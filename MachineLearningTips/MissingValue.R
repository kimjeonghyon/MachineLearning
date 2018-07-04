path <- paste0(getwd(),"/RforPracticalDataAnalysis")
setwd(path)
#install.packages("DMwR")
library("DMwR")
#DMwR::knnImputation : NA -> kNN
iris_na <- iris
iris_na[c(10,20,25,40,32), 3] <- NA
iris_na[c(33,100,123), 1] <- NA
iris_na[!complete.cases(iris_na), ]

iris_na[is.na(iris_na$Sepal.Length),]

median(iris_na$Sepal.Length, na.rm = TRUE)
mapply(median, iris_na[1:4], na.rm = TRUE)

iris_na[!complete.cases(iris_na),]
centralImputation(iris_na[1:4])[c(10,20,25,32,33,40,100,123),]
knnImputation(iris_na[1:4])[c(10,20,25,32,33,40,100,123),] # auto scaling
