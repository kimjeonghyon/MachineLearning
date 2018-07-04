# ROC 커브
# ROCR::prediction
# ROCR::performance

set.seed(137)
probs <- runif(100)
labels <- as.factor(ifelse(probs > .5 & runif(100) < .4, "A","B"))

library(ROCR)
pred <- prediction(probs, labels)
plot(performance(pred, "tpr", "fpr"))
plot(performance(pred, "acc", "cutoff"))
performance(pred, "auc")
