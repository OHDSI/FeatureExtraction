CREATE TABLE @covariate_table (
	covariate_id BIGINT,
	{@temporal}?{time_id BIGINT,}
  {@aggregated}?{
    cohort_definition_id BIGINT,
  	sum_value BIGINT,
	  average_value FLOAT
  }:{
    @row_id_field BIGINT,
    covariate_value INT
  }
	);
	
CREATE TABLE @covariate_continuous_table (
	covariate_id BIGINT,
	{@temporal}?{time_id BIGINT,}
	
  {@aggregated}?{
  cohort_definition_id BIGINT,
  count_value BIGINT,
	min_value FLOAT,
	max_value FLOAT,
	average_value FLOAT,
	standard_deviation FLOAT,
	median_value FLOAT,
	p10_value FLOAT,
	p25_value FLOAT,
	p75_value FLOAT,
	p90_value FLOAT
  }:{
  @row_id_field BIGINT,
  covariate_value FLOAT
  }
	
	);
	
CREATE TABLE @covariate_ref_table (
	covariate_id BIGINT,
	covariate_name VARCHAR(512),
	analysis_id INT,
	concept_id INT,
	value_as_concept_id INT,
	collisions INT
	);
	
CREATE TABLE @analysis_ref_table (
	analysis_id BIGINT,
	analysis_name VARCHAR(512),
	domain_id VARCHAR(20),
	start_day INT,
	end_day INT,
	is_binary VARCHAR(1),
	missing_means_zero VARCHAR(1)
	);
	
	
CREATE TABLE @time_ref_table (
	time_part VARCHAR(20),
	time_interval BIGINT,
	sequence_start_day BIGINT,
	sequence_end_day BIGINT
	);
