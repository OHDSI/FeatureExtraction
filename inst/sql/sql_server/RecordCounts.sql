-- Feature construction
{@included_concept_table != ''} ? {
	IF OBJECT_ID('tempdb..#concepts_all', 'U') IS NOT NULL
		DROP TABLE #concepts_all;

	CREATE TABLE #concepts_all (
		row_id INT
		, concept_id INT
		, field varchar(20)
		, series INT
		);

		INSERT INTO #concepts_all (row_id, concept_id, field, series)
		SELECT ROW_NUMBER() OVER(PARTITION BY field order by concept_id) AS row_id
					, concept_id
					, field
					, series
		FROM
		(
				SELECT concept_id
							, domain_id AS field
							, 1 AS series
				FROM
					@cdm_database_schema.concept concept
				WHERE concept.domain_id in ('Type Concept', 'Place of Service', 'Visit', 'Condition', 'Procedure', 'Drug')
							AND standard_concept = 'S'
				UNION
				SELECT concept_id
							, 'Status Concept' AS field -- because condition_status does not have a domain
							, 1 AS series
				FROM @cdm_database_schema.concept concept
				WHERE concept_id in (4203942, 4230359, 4033240) -- condition_status_concept_id
							AND standard_concept = 'S'
		) AS concept;


		INSERT INTO #concepts_all (row_id, concept_id, field, series)
		SELECT concepts_all.max_row_id + ROW_NUMBER() OVER(PARTITION BY user_included.field order by user_included.concept_id) AS row_id
					, user_included.concept_id
					, user_included.field
					, user_included.series
		FROM
		(
			SELECT DISTINCT
						concept_id
						, domain_id AS field
						, 2 AS series
			FROM @cdm_database_schema.concept concept
			JOIN
					@included_concept_table user_included
			ON concept.concept_id = user_included.id
			WHERE concept.domain_id in ('Type Concept', 'Place of Service', 'Visit', 'Condition', 'Procedure', 'Drug')
						AND standard_concept = 'S'
			UNION
			SELECT
					id AS concept_id
					, 'Status Concept' AS field
					, 2 AS series
			FROM @included_concept_table user_included
			WHERE user_included.id in (4203942, 4230359, 4033240) -- condition_status_concept_id
			) AS user_included
			JOIN
			(
				SELECT field
							, max(row_id) AS max_row_id
				FROM #concepts_all
				GROUP BY field
			) AS concepts_all
			ON user_included.field = concepts_all.field;


			IF OBJECT_ID('tempdb..#included_concept_all', 'U') IS NOT NULL
				DROP TABLE #included_concept_all;

			CREATE TABLE #included_concept_all (
				concept_id INT
				, field varchar(20) -- we need this because condition_status does not have a domain
				);

			INSERT INTO #included_concept_all (concept_id, field)
			SELECT DISTINCT
						concepts_all.concept_id
						, concepts_all.field
			FROM #concepts_all concepts_all
			JOIN
			(
				SELECT seriesall.field
							, CASE WHEN seriesall.max_row_id = series1.max_row_id then 1 else 2 end AS series
				FROM
					(SELECT field, max(row_id) AS max_row_id FROM #concepts_all group by field) AS seriesall
				left join
					(SELECT field, max(row_id) AS max_row_id FROM #concepts_all WHERE series = 1 group by field) AS series1
				on seriesall.field = series1.field and seriesall.max_row_id = series1.max_row_id
			) max_concepts_all
			ON concepts_all.field = max_concepts_all.field
				and concepts_all.series = max_concepts_all.series;
}


{@aggregated} ? {
IF OBJECT_ID('tempdb..#raw_data', 'U') IS NOT NULL
	DROP TABLE #raw_data;

IF OBJECT_ID('tempdb..#overall_stats', 'U') IS NOT NULL
	DROP TABLE #overall_stats;

IF OBJECT_ID('tempdb..#prep_stats', 'U') IS NOT NULL
	DROP TABLE #prep_stats;

IF OBJECT_ID('tempdb..#prep_stats2', 'U') IS NOT NULL
	DROP TABLE #prep_stats2;


SELECT subject_id,
	cohort_start_date,
{@temporal} ? {
    time_id,
}
	records_count
INTO #raw_data
} : {
SELECT 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    time_id,
}
	row_id,
	records_count AS covariate_value
INTO @covariate_table
}
FROM (
	SELECT
{@temporal} ? {
		time_id,
}
{@aggregated} ? {
		subject_id,
		cohort_start_date,
} : {
		cohort.@row_id_field AS row_id,
}
	{@analysis_id IN (120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,320,321,322,323)} ? {
		COUNT(DISTINCT @domain_table.@domain_table_id)
	}
	{@analysis_id IN (220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294)} ? {
		SUM(DATEDIFF(DAY, @domain_table.@domain_start_date, @domain_table.@domain_end_date)+1)
	}
	{@analysis_id IN (420,421,422,423)} ? {
		SUM(@domain_table.days_supply)
	}
		as records_count
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.@domain_table
		ON cohort.subject_id = @domain_table.person_id
				{@analysis_id IN (121,125,126,129,130,131,141,145,146,149,150,151,161,165,166,169,170,171,221,225,226,229,230,231,241,245,246,249,250,251,261,265,266,269,270,271)} ? {
					INNER JOIN
					(
								SELECT DISTINCT visit_occurrence_id
								FROM
										@cdm_database_schema.visit_occurrence
								INNER JOIN
								(
									SELECT DISTINCT care_site_id
									FROM @cdm_database_schema.care_site care_site
									WHERE care_site.care_site_id != 0
									{@included_concept_table != ''} ? {
												AND care_site.place_of_service_concept_id IN (SELECT concept_id FROM #included_concept_all WHERE field = 'Place of Service') -- NULLable field, NULL records are excluded, concept_id = 0 is included
									}
									{@excluded_concept_table != ''} ? {
												AND care_site.place_of_service_concept_id NOT IN (SELECT id FROM @excluded_concept_table)
									}
								) care_site
							ON visit_occurrence.care_site_id = care_site.care_site_id
						) care_site
						 ON @domain_table.visit_occurrence_id = care_site.visit_occurrence_id
				}
				{@analysis_id IN (122,125,128,129,130,132,133,142,145,148,149,150,152,153,162,165,168,169,170,172,173,222,225,228,229,230,232,233,242,245,248,249,250,252,253,262,265,268,269,270,272,273)} ? {
				 INNER JOIN
				 	(
							SELECT DISTINCT visit_occurrence_id
							FROM @cdm_database_schema.condition_occurrence condition_occurrence
							WHERE condition_occurrence.visit_occurrence_id != 0
							{@included_concept_table != ''} ? {
										AND condition_occurrence.condition_type_concept_id IN (select concept_id from #included_concept_all WHERE field = 'Type Concept')	-- Not NULLable field
										AND condition_occurrence.condition_status_concept_id IN (select concept_id from #included_concept_all WHERE field = 'Status Concept') -- NULLable field, NULL records are excluded, concept_id = 0 is included
										AND condition_occurrence.condition_concept_id IN (select concept_id from #included_concept_all WHERE field = 'Condition') -- Not NULLable field
							}
							{@excluded_concept_table != ''} ? {
										AND condition_occurrence.condition_concept_id NOT IN (SELECT id FROM @excluded_concept_table)
										AND condition_occurrence.condition_type_concept_id NOT IN (SELECT id FROM @excluded_concept_table)
										AND condition_occurrence.condition_status_concept_id NOT IN (SELECT id FROM @excluded_concept_table)
							}
					) condition_occurrence
						ON @domain_table.visit_occurrence_id = condition_occurrence.visit_occurrence_id
			 }
			 {@analysis_id IN (123,126,128,130,132,134,150,151,152,154,163,166,168,170,171,172,174,223,226,228,230,232,234,250,251,252,254,263,266,268,270,271,272,274)} ? {
				INNER JOIN
			 (
					 SELECT DISTINCT visit_occurrence_id
					 FROM @cdm_database_schema.procedure_occurrence procedure_occurrence
					 WHERE procedure_occurrence.visit_occurrence_id != 0
					 {@included_concept_table != ''} ? {
					 			 AND procedure_occurrence.procedure_type_concept_id IN (select concept_id from #included_concept_all WHERE field = 'Type Concept') -- Not NULLable
								 AND procedure_occurrence.procedure_concept_id IN (select concept_id from #included_concept_all WHERE field = 'Procedure') -- NULLable field, NULL records are excluded, concept_id = 0 is included
					 }
					 {@excluded_concept_table != ''} ? {
								 AND procedure_occurrence.procedure_concept_id NOT IN (SELECT id FROM @excluded_concept_table)
								 AND procedure_occurrence.procedure_type_concept_id NOT IN (SELECT id FROM @excluded_concept_table)
					 }
			 ) procedure_occurrence
					 ON @domain_table.visit_occurrence_id = procedure_occurrence.visit_occurrence_id
			}
			{@analysis_id IN (124,127,129,130,131,133,134,144,147,149,150,151,153,154,164,167,169,170,171,173,174,224,227,229,230,231,233,234,244,247,249,250,251,253,254,264,267,269,270,271,273,274)} ? {
			 INNER JOIN
			(
					SELECT DISTINCT visit_occurrence_id
					FROM @cdm_database_schema.drug_exposure drug_exposure
					WHERE drug_exposure.visit_occurrence_id != 0
					{@included_concept_table != ''} ? {
								AND drug_exposure.drug_type_concept_id IN (select concept_id from #included_concept_all WHERE field = 'Type Concept') -- Not NULLable
								AND drug_exposure.drug_concept_id IN (select concept_id from #included_concept_all WHERE field = 'Drug') -- Not NULLable
					}
					{@excluded_concept_table != ''} ? {
								AND drug_exposure.drug_concept_id NOT IN (SELECT id FROM @excluded_concept_table)
								AND drug_exposure.drug_type_concept_id NOT IN (SELECT id FROM @excluded_concept_table)
					}
			) drug_exposure
					ON @domain_table.visit_occurrence_id = drug_exposure.visit_occurrence_id
		 }

{@temporal} ? {
	INNER JOIN #time_period time_period
		ON @domain_start_date <= DATEADD(DAY, time_period.end_day, cohort.cohort_start_date)
		AND @domain_start_date >= DATEADD(DAY, time_period.start_day, cohort.cohort_start_date)
		{@analysis_id IN (180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,323,423)} ? {
				AND DATEADD(DAY, time_period.end_day, cohort.cohort_start_date) >= cohort.cohort_start_date -- for InCohort analysis, limits the records with dates between cohort_start_date and cohort_end_date
				AND DATEADD(DAY, time_period.start_day, cohort.cohort_start_date) <= cohort.cohort_end_date
		}
} : {
	WHERE
	@domain_table.@domain_table_id != 0
	{@analysis_id IN (180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,323,423)} ? {
		 AND @domain_start_date >= cohort.cohort_start_date -- for InCohort analysis, limits the records with dates between cohort_start_date and cohort_end_date
		 AND @domain_start_date <= cohort.cohort_end_date
	} : {
		 AND @domain_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
		 AND @domain_start_date >= DATEADD(DAY, @start_day, cohort.cohort_start_date)
	}
}
{@included_concept_table != ''} ? {
	AND @domain_table.@domain_id_type_concept_id IN (select concept_id from #included_concept_all WHERE field = 'Type Concept')
	AND @domain_table.@domain_concept_id IN (select concept_id from #included_concept_all WHERE field = 'Visit')
}
{@excluded_concept_table != ''} ? {
		AND @domain_table.@domain_concept_id NOT IN (SELECT id FROM @excluded_concept_table)
		AND @domain_table.@domain_id_type_concept_id NOT IN (SELECT id FROM @excluded_concept_table)
}
{@cohort_definition_id != -1} ? {AND cohort.cohort_definition_id = @cohort_definition_id}
	GROUP BY
{@temporal} ? {
		time_id,
}
{@aggregated} ? {
		subject_id,
		cohort_start_date
} : {
		cohort.@row_id_field
}
	) raw_data;

{@aggregated} ? {
SELECT CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) THEN MIN(records_count) ELSE 0 END AS min_value,
	MAX(records_count) AS max_value,
	SUM(CAST(records_count AS BIGINT)) / (1.0 * (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id})) AS average_value,
	CASE WHEN COUNT(*) = 1 THEN 0 ELSE SQRT((1.0 * COUNT(*)*SUM(CAST(records_count AS BIGINT) * CAST(records_count AS BIGINT)) - 1.0 * SUM(CAST(records_count AS BIGINT))*SUM(CAST(records_count AS BIGINT))) / (1.0 * COUNT(*)*(1.0 * COUNT(*) - 1))) END AS standard_deviation,
	COUNT(*) AS count_value,
	(SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) - COUNT(*) AS count_no_value,
	(SELECT COUNT(DISTINCT subject_id) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) AS population_size
	{@temporal} ? {
	    ,time_id
	}
INTO #overall_stats
FROM #raw_data
{@temporal} ? {
GROUP BY time_id
}
;

SELECT records_count,
	COUNT(*) AS total,
	ROW_NUMBER() OVER (ORDER BY records_count) AS rn
INTO #prep_stats
FROM #raw_data
GROUP BY records_count;

SELECT s.records_count,
	SUM(p.total) AS accumulated
INTO #prep_stats2
FROM #prep_stats s
INNER JOIN #prep_stats p
	ON p.rn <= s.rn
GROUP BY s.records_count;

SELECT 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    o.time_id,
}
	o.count_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	CASE
		WHEN .50 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .50 * o.population_size THEN records_count	END)
		END AS median_value,
	CASE
		WHEN .10 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .10 * o.population_size THEN records_count	END)
		END AS p10_value,
	CASE
		WHEN .25 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .25 * o.population_size THEN records_count	END)
		END AS p25_value,
	CASE
		WHEN .75 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .75 * o.population_size THEN records_count	END)
		END AS p75_value,
	CASE
		WHEN .90 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .90 * o.population_size THEN records_count	END)
		END AS p90_value
INTO @covariate_table
FROM #prep_stats2 p
CROSS JOIN #overall_stats o
{@included_cov_table != ''} ? {WHERE 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
GROUP BY o.count_value,
	o.count_no_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	o.population_size
	{@temporal} ? {
	    , o.time_id
	}
	;

TRUNCATE TABLE #raw_data;
DROP TABLE #raw_data;

TRUNCATE TABLE #overall_stats;
DROP TABLE #overall_stats;

TRUNCATE TABLE #prep_stats;
DROP TABLE #prep_stats;

TRUNCATE TABLE #prep_stats2;
DROP TABLE #prep_stats2;
}

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
	{@analysis_id IN (120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,320,321,322,323)} ? {
		{@temporal} ? {
		CAST('@domain_table distinct record count' AS VARCHAR(512)) AS covariate_name,
		} : {
			CAST('@domain_table concept count during day @start_day through @end_day records_count relative to index' AS VARCHAR(512)) AS covariate_name,
		}
	}
	{@analysis_id IN (220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,420,421,422,423)} ? {
		{@temporal} ? {
		CAST('@domain_table sum of days in event period' AS VARCHAR(512)) AS covariate_name,
		} : {
			CAST('@domain_table sum of days in event period during day @start_day through @end_day records_count relative to index' AS VARCHAR(512)) AS covariate_name,
		}
	}
	@analysis_id AS analysis_id,
	0 AS concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1;

INSERT INTO #analysis_ref (
	analysis_id,
	analysis_name,
	domain_id,
{!@temporal} ? {
	start_day,
	end_day,
}
	is_binary,
	missing_means_zero
	)
SELECT @analysis_id AS analysis_id,
	CAST('@analysis_name' AS VARCHAR(512)) AS analysis_name,
	CAST('@domain_id' AS VARCHAR(20)) AS domain_id,
{!@temporal} ? {
	CAST(NULL AS INT) AS start_day,
	CAST(NULL AS INT) AS end_day,
}
	CAST('N' AS VARCHAR(1)) AS is_binary,
	CAST('Y' AS VARCHAR(1)) AS missing_means_zero;
