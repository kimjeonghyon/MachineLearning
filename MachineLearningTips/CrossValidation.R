# 교차 검증
# cvTools::cvFolds()

install.packages("cvTools")
library(cvTools)
cvFolds(10, K = 5, type="random")
cvFolds(10, K = 5, type="consecutive")
cvFolds(10, K = 5, type = "interleaved")

set.seed(719)
cv <- cvFolds(nrow(iris), K = 10, R = 3)

cv$which
cv$subsets
validation_idx <- cv$subsets[which(cv$which==1), 1]
which(cv$which==1)
train <- iris[-validation_idx, ] 
validation <- iris[validation_idx, ]

# 교차 검증 사용 템플릿.
# library(foreach)
# set.seed(719)
# R = 3
# K = 10
# cv <- cvFolds(NROW(iris), K=K, R=R)
# foreach(r=1:R) %do% {
#   foreach(k=1:K, .combine = c) %do% { # 결과가 벡터가 되게 한다. 
#     validation_idx <- cv$subsets[which(cv$which == k), r]
#     train <- iris[-validation_idx,]
#     validation <- iris[validation_idx,]
#     # 데이터 전처리
#     
#     # 모델 훈련
#     
#     # 예측
#     
#     # 성능 평가
#     return (성능 값)
#   }
# }
# 
# # foreach 의 반환값으로 부터 성능이 가장 뛰어난 모델링 방법 식별
# # 아이리스 데이터 전체에 대해 해당 방법으로 모델 생성
# 
#   }
# }


# 검증 데이터가 균일하지 않고, 치우친 경우 => y값의 비율이 원본 데이터과 같이 유지
# caret::createDataPartition(), createReadmple(), createFolds(),k createMultiFolds(), createTimeSlices()
# createDataPartition() : 데이터를 훈련데이터와 테스트데이터로 분할한다. 
# createReadmple() : 부트 스트래핑을 사용한 샘플링
# createFolds(), createMultiFolds() : 교차 검증
# createTimeSlices() :

library(caret)
(parts <- createDataPartition(iris$Species, p=0.8)) # Species를 고려하여 데이터를 분리, 훈련데이터인덱스를 리턴한다. 
table(iris[parts$Resample1, "Species"])
table(iris[-parts$Resample1, "Species"])

createFolds(iris$Species, k=10) # 검증데이터의 색인 리턴
createMultiFolds(iris$Species, k=10, times = 3) # time회 반복

# 교차검증 수행 템플릿2
# k <- 10
# times <- 3
# set.seed(137)
# cv <- createMultiFolds(iris$Species, k, times)
# 
# for (i in 1:times) {
#   for (j in 1:k) {
#     train_idx <- cv[[i*times + k]]
#     iris.train <- iris[train_idx, ]
#     iris.validation <- iris[-train_idx, ]
#     # 모델링 수행
#     
#     # 평가
#     
#     }
# }
