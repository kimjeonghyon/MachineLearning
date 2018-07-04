rm (list=ls())


library(randomForest)

all<-factor(c(paste0(LETTERS, "0"), paste0(LETTERS,"1")))
all
data <-data.frame(lvl=all, value=rnorm(length(all)))

m <- randomForest(value ~ lvl, data=data)
summary(m)
# 범주형 변수가 32개 이상 레벨인 경우, 에러 발생

# 원 핫 인코딩
x <- data.frame(lvl=factor(c("A","B", "A","A","C")), 
                value=c(1,2,1,1,3))
x
model.matrix(~ lvl, data=x)[,-1]
