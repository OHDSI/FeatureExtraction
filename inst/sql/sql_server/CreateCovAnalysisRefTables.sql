IF OBJECT_ID('tempdb..#cov_ref', 'U') IS NOT NULL
	DROP TABLE #cov_ref;
	
IF OBJECT_ID('tempdb..#analysis_ref', 'U') IS NOT NULL
	DROP TABLE #analysis_ref;

CREATE TABLE #cov_ref (
	covariate_id BIGINT,
	covariate_name VARCHAR(512),
	analysis_id INT,
	concept_id INT
	);
	
CREATE TABLE #analysis_ref (
	analysis_id BIGINT,
	analysis_name VARCHAR(512),
	domain_id VARCHAR(20),
{!@temporal} ? {	
	start_day INT,
	end_day INT,
}
	is_binary VARCHAR(1),
	missing_means_zero VARCHAR(1)
	);
