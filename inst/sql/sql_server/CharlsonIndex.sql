
   
IF OBJECT_ID('tempdb..#charlson_concepts', 'U') IS NOT NULL
	DROP TABLE #charlson_concepts;

CREATE TABLE #charlson_concepts (
	diag_category_id INT,
	concept_id INT
	);

IF OBJECT_ID('tempdb..#charlson_scoring', 'U') IS NOT NULL
	DROP TABLE #charlson_scoring;

CREATE TABLE #charlson_scoring (
	diag_category_id INT,
	diag_category_name VARCHAR(255),
	weight INT
	);

--acute myocardial infarction
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	1,
	'Myocardial infarction',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 1,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (45766075, 312327, 434376, 438438, 438170, 438447, 441579, 
  436706, 4270024, 4296653, 46270162, 46270163, 43020460, 
  45766116, 444406, 4329847, 37309626, 314666, 4108217, 4108677, 
  4108218, 45766241, 45766114, 439693)
;

--Congestive heart failure
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	2,
	'Congestive heart failure',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 2,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (443580, 4273632, 4195785, 4190773, 320122, 4172864, 316994, 
  439846, 444101, 314378, 439694, 439696, 44782728, 4004279, 
  316139, 4110961, 318773, 4163710, 443587, 315295, 319835, 
  40482727, 40479192, 4014159, 444031, 40479576, 4229440, 
  44782719, 320746, 321319, 4215802, 4242669, 439698, 40480603, 
  4233424, 40480602, 37309625, 40481043, 44782733, 40481042, 
  44782718)
;

--Peripheral vascular disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	3,
	'Peripheral vascular disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 3,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (4316222, 192673, 4134603, 312939, 433222, 436996, 441051, 
  441875, 320646, 317305, 312343, 195559, 44782775, 321052, 
  317309, 36712807, 36712805, 4325344, 37312520, 36712806, 
  36717286, 36717006, 37312529, 442774, 321882, 36717279, 
  37312531, 36712963, 134380, 432346, 37016882, 436136, 37016889, 
  201043, 37109512, 46272492, 320739, 4256889, 199064, 44782819, 
  35611566, 35615028, 195834, 40484551, 46271459, 40483538, 
  40484541, 37110250, 40479625, 315558, 312934, 318443, 317577, 
  317585, 443622, 4332246, 321314, 198177)
;

--Cerebrovascular disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	4,
	'Cerebrovascular disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 4,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (4164092, 374060, 42535426, 4338523, 4108360, 40480002, 
  43530679, 443551, 43531622, 4006294, 374055, 4338227, 759831, 
  4319328, 4111710, 4213731, 4288310, 313226, 4112020, 4311124, 
  4111711, 4045749, 380747, 45766199, 372924, 316437, 4190891, 
  375557, 376713, 4110189, 443454, 4111714, 4108356, 45772786, 
  4110190, 46273649, 46270031, 4110192, 45767658, 374384, 
  441874, 45766121, 381316, 381591, 43530851, 4176892, 4121341, 
  43022059, 4159164, 4153380, 37016924, 43530687, 443465, 
  40479575, 43530688, 44782781, 40481762, 40484522, 40484513, 
  443916, 4180158, 312938, 4043731, 4110185, 4110186, 4353709, 
  439847, 4179912, 4046360, 434056, 4027461, 4110194, 197303, 
  443525, 40480938, 40480946, 40482266, 40481842, 378774, 
  381036, 4144154, 4111709, 314667, 436430, 4111716, 4112024, 
  4112023, 4111717, 372654, 443609, 443599, 43530742, 4110195, 
  42872891, 443239, 4045737, 4045738, 40482301, 45773220, 
  40480449, 43530623, 4112026, 4111721, 4111720, 40481354, 
  43530674, 43530727, 42539269, 42535425, 42535424, 42538062, 
  4148906, 432923, 4108952, 4111708, 433505, 4049659, 439040, 
  433195, 373503, 437306, 4274969, 434656, 4273526, 376714, 
  43531621, 43531583, 44782753, 43530744)
;

--Dementia
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	5,
	'Dementia',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 5,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (378419, 37111242, 44782726, 4182210, 4228133, 374888, 
  4314734, 4180284, 40483103, 44782422, 44782710, 43530666, 
  44782727, 37017319, 36687122, 4046090, 379778, 444091, 
  443790, 443864, 377254, 378125, 381832, 44782771, 377527, 
  4218017, 4220313, 4152048, 373179, 4048875, 376946, 380986, 
  379784, 4047747, 376085, 375791, 443605, 4046089, 37018688, 
  37109056)
;

--Chronic pulmonary disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	6,
	'Chronic pulmonary disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 6,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (45771045, 40483342, 257004, 43530693, 46270376, 45773005, 
  46270082, 46273487, 45769438, 45769442, 45769443, 45769352, 
  45769351, 45769350, 37116845, 4191479, 4236624, 256450, 
  46269801, 4250128, 317009, 4148124, 437588, 4032314, 4221139, 
  439853, 256449, 256451, 4133623, 4311814, 4302900, 4286497, 
  4051466, 256448, 42539089, 255841, 4110048, 4195892, 4112814, 
  255573, 4110056, 44782732, 315831, 252348, 3655113, 252946, 
  313236, 4328679, 40493243, 259043, 258780, 4138760, 45768908, 
  444084, 435298, 4322799, 4027669, 4066407, 434670, 312950, 
  4145497, 4119298, 434975, 438175, 4146581, 4143828, 4110051, 
  4112826, 4142738, 257905, 433233, 4177944, 259044, 4112676, 
  254389, 442125, 256146, 4249010, 258781, 261325, 4167085, 
  4167085, 4266525, 4117865, 4152913, 4145356, 261889, 4196950, 
  443890, 45768910, 45768963, 45768964, 45768965)
;

--Rheumatologic disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	7,
	'Rheumatologic disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 7,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (4344166, 4005037, 4135937, 80182, 4081250, 4344161, 4063581, 
  46273369, 81097, 4343935, 74125, 37395588, 4055369, 4055640, 
  255304, 4107913, 4105026, 4079978, 255348, 80800, 46270482, 
  4102493, 40485046, 4145240, 80809, 4117687, 4115161, 4116440, 
  4116150, 4116151, 42534834, 42534835, 37108590, 35609009, 
  36685020, 4117686, 36685022, 42534836, 42534837, 37108591, 
  35609010, 36685024, 4114439, 4116441, 36684997, 256197, 
  37395590, 4162539, 4271003, 4083556, 4035611, 254443, 4285717, 
  4142899, 257628, 4344158, 4149913, 134442, 4063582, 4290976)
;

--Peptic ulcer disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	8,
	'Peptic ulcer disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 8,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (4027729, 441062, 4336230, 435855, 434402, 437021, 4265479, 
  434070, 435578, 4138962, 435859, 440755, 4231580, 198467, 
  4169592, 199855, 193795, 195845, 4057953, 200137, 194680, 
  4195231, 192954, 199062, 4274491, 441063, 4217947, 441328, 
  438468, 442314, 4280942, 435846, 437598, 4147683, 432951, 
  436460, 4046500, 23237, 4006994, 27026, 31335, 194986, 
  4194543, 26718, 30439, 4163865, 195584, 198187, 4232181, 
  437323, 4289830, 438796, 436148, 440756, 4173408, 439058, 
  432354, 4222896, 443770, 433246, 4211001, 201885, 4294973, 
  196442, 197018, 198801, 4150681, 4206315, 197914, 4296611, 
  195583, 200769, 433515, 436729, 4164920, 437326, 443779, 
  4101870, 444102, 435579, 4177387, 434400, 438795, 4174044, 
  24076, 4247008, 22665, 30770, 24397, 4146517, 30442, 23247, 
  4204555, 24973, 23808, 4031954, 4209746, 435305, 438469, 
  4265600, 4248429, 196443, 195851, 4059178, 4101104, 438188, 
  439858, 4027663, 4291028, 200771, 201069, 4198381)
;

--Mild liver disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	9,
	'Mild liver disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 9,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (201343, 196463, 193256, 4340385, 4340383, 201612, 46269816, 
  200762, 192675, 4058696, 4026125, 200763, 198964, 4238978, 
  201613, 199867, 4012113, 192240, 439674, 763021, 194692, 
  4059284, 4064161, 194984, 46273476, 46269835, 439675, 4308946, 
  196029, 4267417, 4340948, 194417, 4337543, 4340394, 4159144, 
  194990, 4240725, 4135822, 4046123, 4059290, 4059299, 4059298, 
  4058695, 42537742, 198683, 193693)
;

--Diabetes (mild to moderate)
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	10,
	'Diabetes (mild to moderate)',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 10,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (4196141, 443735, 4221933, 45769832, 43531616, 201820, 
  4008576, 443727, 37016348, 37016349, 443592, 4226238, 201531, 
  201530, 4226798, 4228112, 36714116, 4095288, 4224254, 4228443, 
  4327944, 4096041, 4096042, 201254, 4152858, 4099214, 443412, 
  201826, 4099651, 4193704, 40482801)
;

--Diabetes with chronic complications
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	11,
	'Diabetes with chronic complications',
	2
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 11,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (4175440, 37016767, 37016768, 376979, 4225656, 4221495, 
  43531578, 442793, 4048028, 435216, 443732, 443767, 4224419, 
  42538169, 443733, 192279, 443730, 4224879, 377821, 376065, 
  4226354, 4223303, 4222876, 4191611, 4143857, 4140466, 45770830, 
  380097, 4096671, 4096670, 378743, 37016179, 45757435, 377552, 
  37016180, 45770881, 4225055, 4222415, 40480000, 4099652, 
  4044391, 45763583, 43530656, 4131908, 318712, 443729, 321822, 
  376112, 37017431, 37017432, 380096, 45763584, 43530685, 
  200687, 443731, 4174977, 4227210, 376114, 4290822, 4266637, 
  4338901, 45769873, 45773064)
;

--Hemoplegia or paralegia
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	12,
	'Hemoplegia or paralegia',
	2
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 12,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (4102342, 193186, 134331, 4134120, 4104204, 43530718, 
  40480416, 40481376, 4173811, 372880, 132617, 372613, 40481757, 
  40481820, 4101738, 4104848, 374022, 40482237, 40480429, 
  134031, 192901, 37019108, 43530719, 40480514, 40480066, 
  374336, 381548, 195240, 4144328, 4141654, 379012, 380393, 
  380393, 40481345, 442543, 440377, 374377, 43531639, 192606, 
  44782711, 375528, 40480944, 40480435, 44806793, 4101739, 
  4102341, 374914)
;

--Renal disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	13,
	'Renal disease',
	2
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 13,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (44784439, 312358, 442075, 46271022, 443614, 443601, 443597, 
  45763854, 45763855, 443612, 443611, 44782690, 4056462, 
  46270347, 4055899, 4056480, 4059463, 4059584, 45770906, 
  198185, 193782, 44784621, 439694, 439695, 443919, 198124, 
  43020455, 252365, 4146996, 433257, 4298809, 192359, 197921, 
  42539502)
;

--Any malignancy
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	14,
	'Any malignancy',
	2
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 14,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (138708, 135496, 134305, 141816, 36712834, 4079686, 135768, 
  140672, 4189938, 135762, 40483761, 40481524, 140352, 4003184, 
  4002497, 4137687, 4003188, 4297355, 37396742, 4003835, 
  40488896, 4299149, 4003021, 4079282, 4173963, 4082311, 
  434592, 4173974, 4041800, 4097560, 193428, 4091768, 4097561, 
  196055, 315481, 439293, 435758, 433426, 437504, 140057, 
  134597, 133438, 138379, 136056, 760932, 134603, 132572, 
  4133599, 4082487, 40486171, 44808122, 4300704, 4003830, 
  4003832, 4001328, 4002356, 4003831, 138099, 4139358, 4094548, 
  40482893, 4212994, 37395837, 4147411, 45765770, 4003833, 
  4001329, 4002357, 4170421, 40486465, 40490328, 40492267, 
  40492266, 4038845, 4245460, 4217892, 4288751, 4001172, 
  37396884, 4002494, 4038839, 4038835, 436651, 200355, 195761, 
  440965, 434877, 437818, 436652, 316356, 198704, 4041798, 
  432267, 439285, 439282, 141243, 442151, 433161, 442150, 
  313980, 439281, 438373, 201242, 194876, 440351, 438703, 
  442163, 442162, 321522, 198381, 4038843, 435203, 192268, 
  194594, 136655, 434299, 442161, 442160, 315202, 442159, 
  4038842, 434302, 193434, 199760, 136928, 314600, 442158, 
  442157, 315763, 193157, 4041797, 439291, 442156, 440354, 
  442155, 442154, 442153, 320337, 196355, 198986, 438709, 
  442152, 435494, 442144, 140663, 4038840, 198372, 195196, 
  433156, 320049, 442146, 442145, 316649, 198710, 441523, 
  4142878, 4003836, 4001664, 40482847, 434584, 198085, 254583, 
  312846, 4033893, 140958, 258981, 375479, 4038846, 4044708, 
  441235, 40481357, 439761, 444467, 196363, 434595, 444466, 
  436362, 444465, 141814, 197816, 317510, 135766, 132852, 
  193429, 196650, 442095, 439269, 132570, 439268, 318989, 
  4001171, 4038841, 4002358, 132853, 760934, 134596, 200662, 
  440957, 197228, 201810, 135194, 441803, 438380, 198702, 
  318697, 195201, 4041104, 436929, 198098, 192270, 441812, 
  435200, 441525, 197232, 321815, 193721, 4003834, 432571, 
  4094544, 440058, 200349, 195195, 435753, 441521, 438698, 
  192560, 132841, 200343, 4040379, 4245916, 200667, 434601, 
  441245, 435495, 198705, 4095589, 4089860, 4151263, 4095592, 
  141232, 4244051, 434590, 133713, 140048, 139757, 4244488, 
  133714, 438983, 4153890, 4149851, 4032870, 4111917, 197506, 
  40481902, 77812, 377229, 4091467, 258084, 4091490, 4095018, 
  4089777, 201231, 4092358, 4092235, 194286, 40491001, 374297, 
  4095748, 73153, 436045, 4246127, 4095432, 4334322, 4095442, 
  4091464, 4091469, 4092223, 4091486, 4089769, 4091621, 4097284, 
  4094262, 4094260, 4095892, 4097283, 4095304, 75756, 4095430, 
  40482784, 80665, 440655, 4095168, 4092513, 4092515, 4094409, 
  4110889, 4180790, 4116238, 4112734, 4114222, 443389, 4089530, 
  4177242, 4147164, 4094863, 4095312, 4114198, 25189, 4180793, 
  4177236, 4089665, 4116235, 443397, 4118989, 4177112, 4114221, 
  4181485, 4177113, 40481901, 40479608, 40490918, 36684461, 
  4002496, 4264693, 4096968, 4094542, 4225982, 313159, 136930, 
  4033891, 4001666, 321526, 437233, 436059, 4040380, 135204, 
  201813, 442169, 134879, 141524, 138377, 194593, 135764, 
  442168, 40492268, 140666, 760933, 132850, 140967, 132575, 
  4054513, 4180312, 4160342, 4130672, 4131761, 4308811, 4133600, 
  4149840, 194878, 200338, 198088, 435492, 437505, 435207, 
  198707, 320347, 198374, 4038838, 40487528, 133419, 198695, 
  198082, 4032866, 4033318, 4003693, 372849, 258375, 79740, 
  25748, 438095, 133711, 196051, 140955, 321234, 440044, 
  22839, 133710, 444224, 28356, 4003684, 196645, 432558, 
  438691, 4001170, 192261, 4002343, 438090, 198092, 199747, 
  378081, 197803, 436043, 4002498, 4003029, 434881, 133154, 
  760936, 133158, 443743, 4216139, 135214, 373152, 4301668, 
  36716501, 439392, 36684472, 193971, 259748, 4162115, 198104, 
  4162859, 441225, 436348, 436643, 432844, 438982, 436042, 
  438080, 40649300, 80045, 433143, 444203, 4247719, 441513, 
  36684817, 36684820, 256633, 194589, 196360, 434293, 79749, 
  193422, 4162860, 76914, 4246802, 4156114, 380055, 441806, 
  4003674, 4162253, 4187851, 4188545, 4158563, 4187850, 432264, 
  134579, 432838, 27235, 4246029, 432837, 4247822, 432845, 
  433149, 436926, 432848, 380661, 441224, 378696, 4246808, 
  197225, 4003675, 197500, 255192, 373151, 375490, 433975, 
  442134, 4003028, 441800, 42709931, 434587, 435752, 441805, 
  133420, 4247238, 80340, 26638, 140046, 436358, 40486896, 
  374874, 201801, 137809, 201238, 135750, 441233, 132258, 
  435751, 197806, 4179720, 438370, 260336, 437224, 140950, 
  438694, 442131, 440649, 316644, 438979, 434577, 439746, 
  4311480, 435485, 132832, 137219, 138351, 195482, 197804, 
  40490929, 4247331, 25486, 192847, 436913, 440036, 198985, 
  437501, 441802, 4313056, 372567, 4246125, 436352, 26052, 
  440344, 438692, 440345, 40650072, 434292, 434289, 4155171, 
  201519, 436640, 440335, 432263, 201518, 4157454, 441515, 
  193138, 257503, 4247836, 135489, 197507, 379756, 137800, 
  432256, 438693, 4002340, 4247336, 256646, 437805, 4247842, 
  438367, 36684473, 376918, 432559, 4246137, 439404, 441809, 
  432833, 200051, 134290, 199754, 433423, 442122, 196047, 
  139753, 200963, 438086, 441510, 434588, 4246141, 72566, 
  198988, 195483, 4307721, 4003694, 4003179, 4003175, 28083, 
  26361, 24296, 36715801, 78093, 436922, 435474, 435487, 
  436344, 439739, 40650479, 440339, 200962, 438089, 192255, 
  435190, 438699, 74582, 195480, 4311499, 377811, 433704, 
  198091, 438977, 441520, 79758, 434880, 435493, 436635, 
  192836, 254282, 376647, 197807, 438094, 4247358, 317801, 
  197808, 436357, 193719, 136639, 135491, 134295, 193418, 
  437798, 196044, 259755, 439738, 4312691, 441223, 261514, 
  432843, 433976, 433716, 197799, 135476, 438368, 133424, 
  437498, 31509, 433709, 440047, 432262, 432257, 435484, 
  4312698, 436054, 435478, 440956, 81239, 81237, 261236, 
  436353, 252840, 432260, 201517, 200054, 76924, 196049, 
  436923, 76349, 200052, 196359, 45770892, 434285, 196048, 
  438360, 437220, 133969, 132565, 138074, 75488, 261808, 
  441230, 195197, 432254, 40481522, 443719, 436920, 200659, 
  192265, 435193, 441241, 438106, 200660, 139759, 442128, 
  40488812, 4115271, 315497, 4143848, 136656, 4139054, 313430, 
  135499, 4143382, 4041799, 135759, 439267, 439270, 439265, 
  138378, 135765, 439266, 199762, 140664, 195760, 4079683, 
  4003182, 4098597)
;

--Moderate to severe liver disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	15,
	'Moderate to severe liver disease',
	3
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 15,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (201343, 196463, 193256, 4340385, 4340383, 201612, 46269816, 
  200762, 192675, 4058696, 4026125, 200763, 198964, 4238978, 
  201613, 199867, 4012113, 192240, 439674, 763021, 194692, 
  4059284, 4064161, 194984, 46273476, 46269835, 439675, 4308946, 
  196029, 4267417, 4340948, 194417, 4337543, 4340394, 4159144, 
  194990, 4240725, 4135822, 4046123, 4059290, 4059299, 4059298, 
  4058695, 42537742, 198683, 193693)
;

--Metastatic solid tumor
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	16,
	'Metastatic solid tumor',
	6
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 16,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (4160276, 443392, 4131422, 4131428, 4131304, 4130839, 
  4131938, 4133007, 4130842, 443252, 439392, 193144, 4312802, 
  78097, 4246450, 4246451, 378087, 4312290, 140960, 4247962, 
  192568, 4312023, 200959, 439751, 196053, 200348, 46273652, 
  4281027, 198700, 44806773, 254591, 318096, 442182, 320342, 
  434298, 434875, 373425, 199752, 72266, 4147162, 253717, 
  4315806, 196925, 46270513, 4281030, 136354, 198371, 4314071, 
  4158910, 78987, 432851)
;

--AIDS
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	17,
	'AIDS',
	6
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT DISTINCT 17,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE descendant_concept_id IN (37017595, 37017319, 37017244, 4262297, 439727, 4092686, 
  37017446, 37017248, 37017320, 40484012, 37017579)
;

-- Feature construction
{@aggregated} ? {
IF OBJECT_ID('tempdb..#charlson_data', 'U') IS NOT NULL
	DROP TABLE #charlson_data;

IF OBJECT_ID('tempdb..#charlson_stats', 'U') IS NOT NULL
	DROP TABLE #charlson_stats;

IF OBJECT_ID('tempdb..#charlson_prep', 'U') IS NOT NULL
	DROP TABLE #charlson_prep;

IF OBJECT_ID('tempdb..#charlson_prep2', 'U') IS NOT NULL
	DROP TABLE #charlson_prep2;

SELECT cohort_definition_id,
	subject_id,
	cohort_start_date,
	SUM(weight) AS score
INTO #charlson_data
} : {
SELECT CAST(1000 + @analysis_id AS BIGINT) AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
}	
	row_id,
	SUM(weight) AS covariate_value
INTO @covariate_table
}
FROM (
	SELECT DISTINCT charlson_scoring.diag_category_id,
		charlson_scoring.weight,
{@aggregated} ? {
		cohort_definition_id,
		cohort.subject_id,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}			
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.condition_era condition_era
		ON cohort.subject_id = condition_era.person_id
	INNER JOIN #charlson_concepts charlson_concepts
		ON condition_era.condition_concept_id = charlson_concepts.concept_id
	INNER JOIN #charlson_scoring charlson_scoring
		ON charlson_concepts.diag_category_id = charlson_scoring.diag_category_id
{@temporal} ? {		
	WHERE condition_era_start_date <= cohort.cohort_start_date
} : {
	WHERE condition_era_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
	) temp
{@aggregated} ? {
GROUP BY cohort_definition_id,
	subject_id,
	cohort_start_date
} : {
GROUP BY row_id
}	
;

{@aggregated} ? {
WITH t1 AS (
	SELECT cohort_definition_id,
		COUNT(*) AS cnt 
	FROM @cohort_table 
{@cohort_definition_id != -1} ? {	WHERE cohort_definition_id IN (@cohort_definition_id)}
	GROUP BY cohort_definition_id
	),
t2 AS (
	SELECT cohort_definition_id,
		COUNT(*) AS cnt, 
		MIN(score) AS min_score, 
		MAX(score) AS max_score, 
		SUM(score) AS sum_score,
		SUM(score * score) as squared_score
	FROM #charlson_data
	GROUP BY cohort_definition_id
	)
SELECT t1.cohort_definition_id,
	CASE WHEN t2.cnt = t1.cnt THEN t2.min_score ELSE 0 END AS min_value,
	t2.max_score AS max_value,
	CAST(t2.sum_score / (1.0 * t1.cnt) AS FLOAT) AS average_value,
	CAST(CASE WHEN t2.cnt = 1 THEN 0 ELSE SQRT((1.0 * t2.cnt*t2.squared_score - 1.0 * t2.sum_score*t2.sum_score) / (1.0 * t2.cnt*(1.0 * t2.cnt - 1))) END AS FLOAT) AS standard_deviation,
	t2.cnt AS count_value,
	t1.cnt - t2.cnt AS count_no_value,
	t1.cnt AS population_size
INTO #charlson_stats
FROM t1
INNER JOIN t2
	ON t1.cohort_definition_id = t2.cohort_definition_id;

SELECT cohort_definition_id,
	score,
	COUNT(*) AS total,
	ROW_NUMBER() OVER (PARTITION BY cohort_definition_id ORDER BY score) AS rn
INTO #charlson_prep
FROM #charlson_data
GROUP BY cohort_definition_id,
	score;
	
SELECT s.cohort_definition_id,
	s.score,
	SUM(p.total) AS accumulated
INTO #charlson_prep2	
FROM #charlson_prep s
INNER JOIN #charlson_prep p
	ON p.rn <= s.rn
		AND p.cohort_definition_id = s.cohort_definition_id
GROUP BY s.cohort_definition_id,
	s.score;

SELECT o.cohort_definition_id,
	CAST(1000 + @analysis_id AS BIGINT) AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
}
	o.count_value,
	o.min_value,
	o.max_value,
	CAST(o.average_value AS FLOAT) average_value,
	CAST(o.standard_deviation AS FLOAT) standard_deviation,
	CASE 
		WHEN .50 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .50 * o.population_size THEN score	END) 
		END AS median_value,
	CASE 
		WHEN .10 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .10 * o.population_size THEN score	END) 
		END AS p10_value,		
	CASE 
		WHEN .25 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .25 * o.population_size THEN score	END) 
		END AS p25_value,	
	CASE 
		WHEN .75 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .75 * o.population_size THEN score	END) 
		END AS p75_value,	
	CASE 
		WHEN .90 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .90 * o.population_size THEN score	END) 
		END AS p90_value		
INTO @covariate_table
FROM #charlson_prep2 p
INNER JOIN #charlson_stats o
	ON p.cohort_definition_id = o.cohort_definition_id
{@included_cov_table != ''} ? {WHERE 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
GROUP BY o.count_value,
	o.count_no_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	o.population_size,
	o.cohort_definition_id;
	
TRUNCATE TABLE #charlson_data;
DROP TABLE #charlson_data;

TRUNCATE TABLE #charlson_stats;
DROP TABLE #charlson_stats;

TRUNCATE TABLE #charlson_prep;
DROP TABLE #charlson_prep;

TRUNCATE TABLE #charlson_prep2;
DROP TABLE #charlson_prep2;	
} 

TRUNCATE TABLE #charlson_concepts;

DROP TABLE #charlson_concepts;

TRUNCATE TABLE #charlson_scoring;

DROP TABLE #charlson_scoring;

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
	CAST('Charlson index - Romano adaptation' AS VARCHAR(512)) AS covariate_name,
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
	@end_day AS end_day,
}
	CAST('N' AS VARCHAR(1)) AS is_binary,
	CAST('Y' AS VARCHAR(1)) AS missing_means_zero;

