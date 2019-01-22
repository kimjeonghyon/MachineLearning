#1. Auction_master_train.csv 
# – 서울/부산 지역의 낙찰가를 포함하여 경매 물건 아파트의 위치, 감정가, 경매 개시/종결일 등의 기본 정보(*최근2년)
#2. Auction_master_test.csv 
# – 경매 낙찰가를 제외하고 train.csv와 동일 
#3. Auction_submission.csv – 예측한 낙찰가를 기입하여 제출
#4. Auctiuon_regist.csv – 아파트에 대한 등기 정보
#   *개별 경매: 1개의 사건 번호에 여러 물건으로 경매 진행될 경우
#   *과다등기: 등기명의인 수가 100인(말소등기포함)을 초과하는 경우
#   *개별 경매 중 다음과 같은 사항이 발생 시, 등기 정보가 누락될 수 있습니다.
#     a.모든 물건의 등기부등본이 동일한 경우(1개만 발급받은 경우)
#     b.과다등기로 인한 등기부등본 발급이 어려운 경우 
#       (예: 등기부등본에 채권자, 소유주 등 등재인이 너무 많아 등기부등본 발급이 안되는 경우)
#5. Auctiuon_result.csv – 경매일자, 감정가, 최저매각가격, 경매 결과 데이터.
#6. Auctiuon_rent.csv – 해당 아파트에 임차인이 있는 경우, 전입/점유 여부, 보증금, 월세 등의 데이터.

rm (list=ls())
setwd("D:/RDev/dacon/3rdCompetition")

suppressMessages(library(tidyverse))
suppressMessages(library(gridExtra))
#suppressMessages(library(ROCR))
#suppressMessages(library(glmnet))
#suppressMessages(library(MASS))
suppressMessages(library(randomForest))
#suppressMessages(library(gbm))
#suppressMessages(library(rpart))
#suppressMessages(library(boot))
suppressMessages(library(Hmisc))
suppressMessages(library(data.table))
suppressMessages(library(pls))

options(scipen = 999)

panel.cor <- function(x, y, digits = 2, prefix = "", cex.cor, ...)
  {
         usr <- par("usr"); on.exit(par(usr))
         par(usr = c(0, 1, 0, 1))
         r <- abs(cor(x, y))
         txt <- format(c(r, 0.123456789), digits = digits)[1]
         txt <- paste0(prefix, txt)
         if(missing(cex.cor)) cex.cor <- 0.8/strwidth(txt)
         text(0.5, 0.5, txt, cex = cex.cor * r)
  }


rmse <- function(yi, yhat_i){
  sqrt(mean((yi-yhat_i)^2))
}


mae <- function(yi, yhat_i) {
  mean(abs(yi-yhat_i))
}
detach_package <- function(pkg, character.only = FALSE)
{
  if(!character.only)
  {
    pkg <- deparse(substitute(pkg))
  }
  search_item <- paste("package", pkg, sep = ":")
  while(search_item %in% search())
  {
    detach(search_item, unload = TRUE, character.only = TRUE)
  }
}

setwd("D:/RDev/dacon/3rdCompetition")
master_train <- read.csv('./Auction_master_kr/Auction_master_train.csv', header = TRUE, stringsAsFactors=F, fileEncoding = 'utf8')
master_test <- read.csv('./Auction_master_kr/Auction_master_test.csv', header = TRUE, stringsAsFactors=F,fileEncoding = 'utf8')
regist <- read.csv('./Auction_master_kr/Auction_regist.csv', header = TRUE, stringsAsFactors=F,fileEncoding = 'utf8')
rent <- read.csv('./Auction_master_kr/Auction_rent.csv', header = TRUE, stringsAsFactors=F,fileEncoding = 'utf8')
result <- read.csv('./Auction_master_kr/Auction_result.csv', header = TRUE, stringsAsFactors=F,fileEncoding = 'utf8')


#############################################################
# 자료 가공 
#############################################################
master_train <- master_train %>% 
  dplyr::select (Auction_key, 
                 Bid_class, # 입찰 구분
                 yc = Auction_miscarriage_count,  # 유찰 횟수
                 Total_appraisal_price, # 총감정가
                 Minimum_sales_price, # 최저매각가격 
                 Share_auction_YorN, # 지분경매 여부,
                 addr_si, # 강남구, 해운대구 
                 Hammer_price) # 낙찰가

master_test <- master_test %>% 
  dplyr::select (Auction_key, 
                 Bid_class, # 입찰 구분
                 yc = Auction_miscarriage_count,  # 유찰 횟수
                 Total_appraisal_price, # 총감정가
                 Minimum_sales_price, # 최저매각가격 
                 Share_auction_YorN, # 지분경매 여부,
                 addr_si, # 강남구, 해운대구 
                 Hammer_price) # 낙찰가

# 등기종류와 등기기록을 컬럼으로 뽑아낸다. 
# 말소 기준 권리일 구하기
regist <- regist %>% 
  mutate(Regist_class = str_trim(Regist_class),
         Regist_type = str_trim(Regist_type))


# 말소 기준 권리 일자를 뽑는다.
malso <- regist %>% 
  filter(Regist_class %in% c("가압","강제","임의","압류","저당","가등기","전세권")) %>% 
  arrange(Auction_key, Auction_seq) %>% 
  group_by(Auction_key) %>% 
  filter(Auction_seq == min(Auction_seq)) %>% 
  select (Auction_key, malso_date = Regist_date)

# malso 과 조인한다. : malso date 추가
master_train <- master_train %>% 
  left_join(malso, by = "Auction_key") 

master_test <- master_test %>% 
  left_join(malso, by = "Auction_key") 

# 등기 종류별로 파생컬럼 생성
regist_sum <- regist %>% 
  mutate(rgt_type1=ifelse(Regist_type=="건물등기",1,0),
         rgt_type2=ifelse(Regist_type=="기타등기",1,0),
         rgt_type3=ifelse(Regist_type=="집합건물등기",1,0),
         rgt_type4=ifelse(Regist_type=="토지별도등기",1,0),
         rgt_class1=ifelse(Regist_class=="소유이전",1,0),
         rgt_class2=ifelse(Regist_class=="가압",1,0),
         rgt_class3=ifelse(Regist_class=="가처분",1,0),
         rgt_class4=ifelse(Regist_class=="강제",1,0),
         rgt_class5=ifelse(Regist_class=="임의",1,0),
         rgt_class6=ifelse(Regist_class=="압류",1,0),
         rgt_class7=ifelse(Regist_class=="저당",1,0),
         rgt_class8=ifelse(Regist_class=="질권",1,0),
         rgt_class9=ifelse(Regist_class=="가등기",1,0),
         rgt_class10=ifelse(Regist_class=="보전처분",1,0),
         rgt_class11=ifelse(Regist_class=="이전",1,0),
         rgt_class12=ifelse(Regist_class=="전세권",1,0),
         rgt_class13=ifelse(Regist_class=="임차권",1,0),
         rgt_class14=ifelse(Regist_class=="예고등기",1,0)
  ) %>% 
  group_by(Auction_key) %>% 
  summarise(rgt_type1_sum = ifelse(sum(rgt_type1) > 0, 'Y','N'),
            rgt_type2_sum = ifelse(sum(rgt_type2) > 0, 'Y','N'),
            rgt_type3_sum = ifelse(sum(rgt_type3) > 0, 'Y','N'),
            rgt_type4_sum = ifelse(sum(rgt_type4) > 0, 'Y','N'),
            rgt_class1_sum = ifelse(sum(rgt_class1) > 0, 'Y','N'),
            rgt_class2_sum = ifelse(sum(rgt_class2) > 0, 'Y','N'),
            rgt_class3_sum = ifelse(sum(rgt_class3) > 0, 'Y','N'),
            rgt_class4_sum = ifelse(sum(rgt_class4) > 0, 'Y','N'),
            rgt_class5_sum = ifelse(sum(rgt_class5) > 0, 'Y','N'),
            rgt_class6_sum = ifelse(sum(rgt_class6) > 0, 'Y','N'),
            rgt_class7_sum = ifelse(sum(rgt_class7) > 0, 'Y','N'),
            rgt_class8_sum = ifelse(sum(rgt_class8) > 0, 'Y','N'),
            rgt_class9_sum = ifelse(sum(rgt_class9) > 0, 'Y','N'),
            rgt_class10_sum = ifelse(sum(rgt_class10) > 0, 'Y','N'),
            rgt_class11_sum = ifelse(sum(rgt_class11) > 0, 'Y','N'),
            rgt_class12_sum = ifelse(sum(rgt_class12) > 0, 'Y','N'),
            rgt_class13_sum = ifelse(sum(rgt_class13) > 0, 'Y','N'),
            rgt_class14_sum = ifelse(sum(rgt_class14) > 0, 'Y','N')
            )

# regist_sum 과 조인한다. : 등기종류별 컬럼 추가
master_train <- master_train %>% 
  left_join(regist_sum, by = "Auction_key") 

master_test <- master_test %>% 
  left_join(regist_sum, by = "Auction_key") 


# 전입 신고 일자, 보증금, 월세 정보를 뽑아낸다.  
rent <- rent %>% 
  mutate(Rent_class = str_trim(Rent_class))

rent_s <- rent %>% 
  mutate(Rent_date = paste0(substr(Rent_date,1,4),substr(Rent_date,6,7),substr(Rent_date,9,10))) %>% 
  filter(Rent_class =='전입') %>% 
  select (Auction_key = Auctiuon_key, Purpose_use, Rent_deposit, Rent_date,Rent_deposit,Rent_monthly_price )

# rent_s 과 조인한다. : 임대차 정보 추가
master_train <- master_train %>% 
  left_join(rent_s, by = "Auction_key") 

master_test <- master_test %>% 
  left_join(rent_s, by = "Auction_key") 

# malso_date > Rent_date : 임차일이 말소기준권리보다 이전이면, 
#   떠안을 금액이 없다. (배당 요구 가정)
# malso_date <= Rent_date 
#   Rent_deposit 을 떠안아야 한다. 
master_train <- master_train %>% 
  mutate(added_amt = ifelse( (Purpose_use == '주거') & (malso_date <= Rent_date ),Rent_deposit, 0))

master_test <- master_test %>% 
  mutate(added_amt = ifelse( (Purpose_use == '주거') & (malso_date <= Rent_date ),Rent_deposit, 0))

# 변수 삭제 
master_train <- master_train %>% 
  select (-c (Purpose_use, malso_date, Rent_date,Rent_deposit))

master_test <- master_test %>% 
  select (-c (Purpose_use, malso_date, Rent_date,Rent_deposit))

# 결측치 처리

master_train %>%
  summarize_all(funs(length(which(is.na(.)))/length(.))) %>% 
  glimpse()

master_train <- master_train %>%
  mutate_if(is.numeric, funs(imp=ifelse(is.na(.), 0, .))) %>%
  mutate_if(is.character, funs(imp=ifelse(is.na(.), "N", .))) %>%
  dplyr::select(ends_with("_imp")) %>%
  rename_all(funs(gsub("_imp", "", .)))


master_test <- master_test %>%
  mutate_if(is.numeric, funs(imp=ifelse(is.na(.), 0, .))) %>%
  mutate_if(is.character, funs(imp=ifelse(is.na(.), "N", .))) %>%
  dplyr::select(ends_with("_imp")) %>%
  rename_all(funs(gsub("_imp", "", .)))

# 범주화 
si_level <- rbind(master_train,master_test) %>%
  distinct(addr_si) %>% 
  arrange()

master_train <- master_train %>% 
  mutate(addr_si = factor(addr_si, level = si_level[,1]),
         Bid_class = factor(Bid_class, level = c("개별","일반","일괄")),
         Share_auction_YorN = factor(Share_auction_YorN, level = c("N","Y")),
         rgt_type1_sum = factor(rgt_type1_sum, levels = c("N","Y")),
         rgt_type2_sum = factor(rgt_type2_sum, levels = c("N","Y")),
         rgt_type3_sum = factor(rgt_type3_sum, levels = c("N","Y")),
         rgt_type4_sum = factor(rgt_type4_sum, levels = c("N","Y")),
         rgt_class1_sum = factor(rgt_class1_sum, levels = c("N","Y")),
         rgt_class2_sum = factor(rgt_class2_sum, levels = c("N","Y")),
         rgt_class3_sum = factor(rgt_class3_sum, levels = c("N","Y")),
         rgt_class4_sum = factor(rgt_class4_sum, levels = c("N","Y")),
         rgt_class5_sum = factor(rgt_class5_sum, levels = c("N","Y")),
         rgt_class6_sum = factor(rgt_class6_sum, levels = c("N","Y")),
         rgt_class7_sum = factor(rgt_class7_sum, levels = c("N","Y")),
         rgt_class8_sum = factor(rgt_class8_sum, levels = c("N","Y")),
         rgt_class9_sum = factor(rgt_class9_sum, levels = c("N","Y")),
         rgt_class10_sum = factor(rgt_class10_sum, levels = c("N","Y")),
         rgt_class11_sum = factor(rgt_class11_sum, levels = c("N","Y")),
         rgt_class12_sum = factor(rgt_class12_sum, levels = c("N","Y")),
         rgt_class13_sum = factor(rgt_class13_sum, levels = c("N","Y")),
         rgt_class14_sum = factor(rgt_class14_sum, levels = c("N","Y"))
         )

master_test <- master_test %>% 
  mutate(addr_si = factor(addr_si, level = si_level[,1]),
         Bid_class = factor(Bid_class, level = c("개별","일반","일괄")),
         Share_auction_YorN = factor(Share_auction_YorN, level = c("N","Y")),
         rgt_type1_sum = factor(rgt_type1_sum, levels = c("N","Y")),
         rgt_type2_sum = factor(rgt_type2_sum, levels = c("N","Y")),
         rgt_type3_sum = factor(rgt_type3_sum, levels = c("N","Y")),
         rgt_type4_sum = factor(rgt_type4_sum, levels = c("N","Y")),
         rgt_class1_sum = factor(rgt_class1_sum, levels = c("N","Y")),
         rgt_class2_sum = factor(rgt_class2_sum, levels = c("N","Y")),
         rgt_class3_sum = factor(rgt_class3_sum, levels = c("N","Y")),
         rgt_class4_sum = factor(rgt_class4_sum, levels = c("N","Y")),
         rgt_class5_sum = factor(rgt_class5_sum, levels = c("N","Y")),
         rgt_class6_sum = factor(rgt_class6_sum, levels = c("N","Y")),
         rgt_class7_sum = factor(rgt_class7_sum, levels = c("N","Y")),
         rgt_class8_sum = factor(rgt_class8_sum, levels = c("N","Y")),
         rgt_class9_sum = factor(rgt_class9_sum, levels = c("N","Y")),
         rgt_class10_sum = factor(rgt_class10_sum, levels = c("N","Y")),
         rgt_class11_sum = factor(rgt_class11_sum, levels = c("N","Y")),
         rgt_class12_sum = factor(rgt_class12_sum, levels = c("N","Y")),
         rgt_class13_sum = factor(rgt_class13_sum, levels = c("N","Y")),
         rgt_class14_sum = factor(rgt_class14_sum, levels = c("N","Y"))
         )

master_test %>% select(ends_with("_sum")) %>% slice(1:3)


str(master_test)
############################################################
# 2단계모형 적용
############################################################

df <- master_train %>% select (-Auction_key)

# 검증 데이터 분할
set.seed(2018)
n <- nrow(df)
idx <- 1:n
training_idx <- sample(idx, n*.70)
idx <- setdiff(idx, training_idx)
validate_idx <- sample(idx, n*.30)
training <- df[training_idx,]
validation <- df[validate_idx,]

# 모델 생성 - 랜덤 포레스트
df_rf <- randomForest(Hammer_price ~ ., training)

# 예측 정확도 지표
y_obs <- validation$Hammer_price
yhat_rf <- predict(df_rf, newdata=validation)
rmse(y_obs, yhat_rf)

# 모델 생성 - lm
describe(training)
# rgt_class14_sum 삭제  (예고등기 3건 밖에 없음)
training <- training %>% select (-rgt_class14_sum)
validation <- validation %>% select (-rgt_class14_sum)
master_test <- master_test %>% select (-rgt_class14_sum)

df_lm_full <- lm(Hammer_price ~ ., data=training)
df_step <- MASS::stepAIC(df_lm_full, scope = list(upper = ~ ., lower = ~1))
y_obs <- validation$Hammer_price
yhat_lm <- predict(df_lm_full, newdata=validation)
yhat_step <- predict(df_step, newdata=validation)
rmse(y_obs, yhat_lm)
rmse(y_obs, yhat_step)


# 모델생성 : PLS
df_pls = plsr(Hammer_price ~ ., data = training, validation="CV")
yhat_pls <- predict(df_pls, newdata=validation, ncomp=1)
rmse(y_obs, yhat_pls)

pls.RMSEP = RMSEP(df_pls, estimate="CV")
plot(pls.RMSEP)
min_comp = which.min(pls.RMSEP$val)
min_comp

yhat_pls <- predict(df_pls, newdata=validation, ncomp=min_comp)
rmse(y_obs, yhat_pls)

rmse(y_obs, yhat_lm)
rmse(y_obs, yhat_step)
rmse(y_obs, yhat_rf)
rmse(y_obs, yhat_pls)

write.csv(data.frame(validation, yhat_step), 'result.csv')

################################################################
# 최적화 
################################################################


## 제출

# 테스트 데이터 생성
df.test <- master_test

yhat_step_test <- predict(df_step, newdata=df.test)

master_test$Hammer_price <- yhat_step_test

write.csv(data.frame(Auction_key= master_test$Auction_key, 
                     Hammer_price = master_test$Hammer_price),"Auction_submission_20181129.csv", row.names = F, quote = F)
