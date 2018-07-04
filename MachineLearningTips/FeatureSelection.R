# 변수 선택

#caret::nearZeroVar : 데이터에서 분산이 0에 가까운 변수를 찾는다. 
library(caret)
#install.packages("mlbench")
library(mlbench)
data(Soybean)
str(Soybean)
nearZeroVar(Soybean, saveMetrics = TRUE)
Soybean$leaf.mild
mySoybean <- Soybean[,-nearZeroVar(Soybean)]
