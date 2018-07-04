# princomp (x, cor=FALSE)
# FALSE : 공분산 행렬, TRUE면 상관행렬을 사용

x <- 1:10
y <- x + runif(10, min=-.5, max=.5)
z <- x + y +runif(10, min= -.10, max = .10)
data <- data.frame(x,y,z)
pr <- princomp(data)
summary(pr)
# 상위 2개 성분의 좌표를 구한다. 
pr$scores[,1:2]
