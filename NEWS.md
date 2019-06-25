FeatureExtraction 2.2.4
=======================

Bugfixes:

1. Removing redundant covariates now precedes removing infrequent covariates when calling tidyCovariates. Anlyses where the most prevalent (redundant) covariate was removed are now exempt from removal of infrequent covariates.

2. Fixed some typos in the vignette


FeatureExtraction 2.2.3
=======================

Changes:

1. Also removing descendants when excluding condition concepts from condition groups. Condition groups therefore now work similar to drug groups.

Bugfixes:

1. Updated workaround for ff bug causing chunk.default error on R v3.6.0 on machines with lots of memory.


FeatureExtraction 2.2.2
=======================

Changes:

1. Using new SqlRender (v1.6.0) functions.


FeatureExtraction 2.2.1
=======================

Changes:

1. Added option to specify number of digits for continuous variables in createTable1 function.

Bugfixes:

1. Added missing space cause SQL error when both include and exclude concept are specified.


FeatureExtraction 2.2.0
=======================

Changes:

1. Added the Hospital Frailty Risk Score.