DROP TABLE IF EXISTS main.cohort;

CREATE TABLE main.cohort (
  cohort_definition_id INT,
  subject_id BIGINT,
  cohort_start_date DATE,
  cohort_end_date DATE
);

-- celecoxib
INSERT INTO main.cohort
SELECT CAST(1 AS INT) AS cohort_definition_id,
person_id,
drug_era_start_date,
drug_era_end_date
FROM main.drug_era
WHERE drug_concept_id = 1118084;

--diclofenac
INSERT INTO main.cohort
SELECT CAST(2 AS INT) AS cohort_definition_id,
person_id,
drug_era_start_date,
drug_era_end_date
FROM main.drug_era
WHERE drug_concept_id = 1124300;

-- Gastrointestinal haemorrhage
INSERT INTO main.cohort
SELECT CAST(3 AS INT) AS cohort_definition_id,
condition_occurrence.person_id AS subject_id,
condition_start_date AS cohort_start_date,
COALESCE(condition_end_date,
         CAST(STRFTIME('%s',TIMESTAMP(condition_start_date, 'unixepoch', (1)||' days')) AS REAL)) AS cohort_end_date
FROM main.condition_occurrence
WHERE condition_concept_id IN (
  SELECT descendant_concept_id
  FROM main.concept_ancestor
  WHERE ancestor_concept_id = 192671
);

-- NSAIDS
INSERT INTO main.cohort
SELECT CAST(4 AS INT) AS cohort_definition_id,
person_id AS subject_id,
MIN(drug_exposure_start_date) AS cohort_start_date,
MIN(drug_exposure_end_date) AS cohort_end_date
FROM main.drug_exposure
INNER JOIN main.concept_ancestor
ON drug_concept_id = descendant_concept_id
WHERE ancestor_concept_id IN (1118084, 1124300)
GROUP BY person_id;
