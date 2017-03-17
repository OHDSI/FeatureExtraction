#
#

test_that("access", {
  print("This is a test of accessing the database")
  # script to connect to the hack-a-thon SYNPUF database in Amazon AWS
  # thanks to Lee Evans!
  
  # On Windows, make sure RTools is installed.
  # The DatabaseConnector and SqlRender packages require Java. Java can be downloaded from http://www.java.com.
  # In R, use the following commands to download and install some packages:
  
  #install.packages("devtools")
  #library(devtools)
  #install_github("ohdsi/OhdsiRTools") 
  #install_github("ohdsi/SqlRender")
  #install_github("ohdsi/DatabaseConnector")
  
  library(DatabaseConnector)
  library(SqlRender)
  
  # connection details for the aws instance (password will be provided)
  dbms <- "redshift"
  user <- "synpuf_training"
  password <- Sys.getenv('dbpasswd')
  
  # for the 1000 sample:
  #server <- "ohdsi.cxmbbsphpllo.us-east-1.redshift.amazonaws.com/synpuf1k"
  
  # for the 1% sample:
  server <- "ohdsi.cxmbbsphpllo.us-east-1.redshift.amazonaws.com/synpuf1pct"
  port <- 5439
  connectionDetails <- createConnectionDetails(dbms = dbms,
                                               user = user,
                                               password = password,
                                               server = server,
                                               port = port)
  connection <- connect(connectionDetails)
  
  sql <- translateSql("select * from cdm.person limit 100", targetDialect = connectionDetails$dbms)$sql
  result <- querySql(connection, sql)
  
  # The cdm schema contains all the cdm tabels and vocabulary and is read only
  # There is "scratch" schema that is writable in which you can create your own tables.
  # Please add your name in the table name to not clash with other participants, e.g rijnbeek-cohort
  
  
  print("done with query")
}
)