install.packages("sqldf")


bassDF <- data.frame(a = 1:5, b=letters[1:5])
newDF <- data.frame(a = 1:3, b=letters[1:3])

require(sqldf)

a1NotIna2 <- sqldf("SELECT * FROM bassDF EXCEPT SELECT * FROM newDF")
a1NotIna2

