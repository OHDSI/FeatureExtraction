{@temp_tables}?{
IF OBJECT_ID('tempdb..@covariate_table', 'U') IS NOT NULL DROP TABLE @covariate_table;
IF OBJECT_ID('tempdb..@covariate_continuous_table', 'U') IS NOT NULL DROP TABLE @covariate_continuous_table;
IF OBJECT_ID('tempdb..@covariate_ref_table', 'U') IS NOT NULL DROP TABLE @covariate_ref_table;
IF OBJECT_ID('tempdb..@analysis_ref_table', 'U') IS NOT NULL DROP TABLE @analysis_ref_table;
IF OBJECT_ID('tempdb..@time_ref_table', 'U') IS NOT NULL DROP TABLE @time_ref_table;
}:{
DROP TABLE IF EXISTS @covariate_table;
DROP TABLE IF EXISTS @covariate_continuous_table;
DROP TABLE IF EXISTS @covariate_ref_table;
DROP TABLE IF EXISTS @analysis_ref_table;
DROP TABLE IF EXISTS @time_ref_table;
}



