#
#

library(SqlRender)
library(DatabaseConnector)

test_that("access", {
  if (Sys.getenv("SYNPUF_DB_PASSWD") != "") {
    print("This is a test of accessing the database")
    
    # connection details for the aws instance (password will be provided)
    dbms <- "redshift"
    user <- "synpuf_training"
    password <- Sys.getenv("SYNPUF_DB_PASSWD")
    
    # for the 1% sample:
    server <- "ohdsi.cxmbbsphpllo.us-east-1.redshift.amazonaws.com/synpuf1pct"
    port <- 5439
    connectionDetails <- createConnectionDetails(dbms = dbms,
                                                 user = user,
                                                 password = password,
                                                 server = server,
                                                 port = port)
    connection <- connect(connectionDetails)
    
    getDbDefaultCovariateData(connection = connection)
  }
})
