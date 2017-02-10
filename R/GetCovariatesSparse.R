#' Learn new features through sparse coding from a set of standardly encoded covariates from the database
#'
#' @description
#' Constructs new features through sparse coding from a default set of covariates for cohorts using data in the CDM schema.
#'
#' @param covariateSettings   An object of type \code{covariateSettings} as created using the
#'                            \code{\link{createCovariateSettingsSparse}} function.
#'
#' @template GetCovarParams
#'
#' @export
getDbCovariateDataSparse <- function(connection,
                                  oracleTempSchema = NULL,
                                  cdmDatabaseSchema=cdmDatabaseSchema,
                                  cdmVersion = "5",
                                  cohortTempTable = cohortTable,
                                  rowIdField = "subject_id",
                                  covariateSettings=covariateSettings,
                                  normalize = TRUE) {


	plpData <- covariateSettings$plpData
	studyPop <- covariateSettings$studyPop
	dataSplit <- covariateSettings$dataSplit

	library(MASS)
	library(spams)                        
	library(ff)

	myCov <- toSparseM(plpData,studyPop)
	myCovData <- Matrix::t(myCov$data)

	# myCovTrain is obtained by dropping columns from myCov which correspond to patients in testing split of the data
	myCovTrain <- myCovData[,-which(rev(dataSplit[,-1])==-1)]

	numVectors <- covariateSettings$numBasisVectors 
	# if user did not specify value for numBasisVectors, set it to twice the number of usual covariates
	if(numVectors == -1){
		numVectors <-  2*nrow(myCovData)
	} 

	# feed myCovTrain into SPAMS package and learn dictionary vectors D
	D <- spams.trainDL(myCovTrain, K = numVectors,lambda1 = covariateSettings$lambda1, numThreads = covariateSettings$numThreads, verbose = FALSE, 
		batchsize = covariateSettings$batchsize,iter = covariateSettings$iter,posAlpha=covariateSettings$posAlpha,posD=covariateSettings$posD)

	# use SPAMS to learn coefficients alpha to represent each person's covariate vector as linear combination of dictionary vectors
	# learn coefficients for patients in both train and test set
	alpha = spams.omp(as.matrix(myCovData),D,eps=covariateSettings$eps,lambda1=covariateSettings$lambda1,return_reg_path = FALSE, numThreads = covariateSettings$numThreads)

	if(covariateSettings$useUsualCovariatesAlso){
		# newCov1 contains subjectIDs, first corresponding to new covariates, then corresponding to original covariates
		newCov1 <- c(rep(studyPop$rowId, each=nrow(alpha)), plpData$covariates[,1])

		# newCov2 contains covariate IDs 
		newCov2Helper <- seq(1,nrow(alpha),length=nrow(alpha))
		newCov2 <- c(rep(newCov2Helper,ncol(alpha)),  plpData$covariates[,2])

		# newCov3 contains covariate values
		newCov3 <- c(as.vector(alpha),  plpData$covariates[,3])

		covariateRef <- data.frame(covariateId=c(seq(1,nrow(alpha),length=nrow(alpha)), plpData$covariateRef[,1]),
			covariateName = c(paste("sparse",seq(1,nrow(alpha),length=nrow(alpha)),sep=""),paste(plpData$covariateRef[,2])),
			analysisId=seq(1,1,length=nrow(alpha)+length(plpData$covariateRef[,2])), conceptId=seq(0,0,length=nrow(alpha)+length(plpData$covariateRef[,2])))
	}else{
		# newCov1 contains subjectIDs corresponding to new covariates obtained through sparse coding
		newCov1 <- rep(studyPop$rowId, each=nrow(alpha))

		# newCov2 contains covariate IDs 
		newCov2Helper <- seq(1,nrow(alpha),length=nrow(alpha))
		newCov2 <- rep(newCov2Helper,ncol(alpha))

		# newCov3 contains covariate values
		newCov3 <- as.vector(alpha)

		covariateRef <- data.frame(covariateId=seq(1,nrow(alpha),length=nrow(alpha)),
			covariateName = paste("sparse",seq(1,nrow(alpha),length=nrow(alpha)),sep=""),
			analysisId=seq(1,1,length=nrow(alpha)), conceptId=seq(0,0,length=nrow(alpha)))
	}

	newCovFF <- data.frame(rowId=newCov1,covariateId=newCov2,covariateValue=newCov3)
	newCovFF <- as.ffdf(newCovFF)
	covariateRef <- as.ffdf(covariateRef)
	metaData <- list(call = match.call())
	result <- list(covariates=newCovFF, covariateRef=covariateRef,metaData=metaData)
	class(result) <- "covariateData"
	return(result) 
}





#' Create covariate settings
#'
#' @details
#' creates an object specifying how new features should be contructed through sparse coding from
#' standardly encoded covariates.
#'
#' @param plpData              A plpData object
#'                                                 
#' @param studyPop              
#'                                                 
#' @param dataSplit                 
#'                                                 
#'                                                  
#'                                                 
#'                                                  
#'
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#'
#' @export
createCovariateSettingsSparse <- function(plpData, studyPop, dataSplit, numBasisVectors = -1, useUsualCovariatesAlso = TRUE, lambda1 = 0.2, numThreads = -1, batchsize = 400, iter = 1000, posAlpha=FALSE, posD=TRUE, eps=0.001) { 
	covariateSettings <- list(plpData = plpData, studyPop = studyPop, dataSplit = dataSplit, numBasisVectors = numBasisVectors, useUsualCovariatesAlso = useUsualCovariatesAlso, 
		lambda1 = lambda1, numThreads = numThreads, batchsize = batchsize, iter = iter, posAlpha=posAlpha, posD=posD, eps=eps)
	attr(covariateSettings, "fun") <- "getDbCovariateDataSparse" 
	class(covariateSettings) <- "covariateSettings" 
	return(covariateSettings)
}

