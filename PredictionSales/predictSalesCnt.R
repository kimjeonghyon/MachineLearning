rm(list=ls())
setwd("D:/07. 자료/머신러닝/datamonster_lgcns/2018_DM_MISSION/Mission1_수요예측")

# 분석대상: 2015년 1월 1일 ~ 2016년 5월 31일까지 12개 자재에 대한 일별 판매량 데이터
# 블러셔	32900539	립&아이리무버	30400512
# 아이라이너	34200266	선케어	31500200
# 아이라이너	32800575	시트	32500391
# 아이브로우	34200131	클렌징폼	304s00521
# 아이브로우 펜슬	32900535	필링	32400198
# 아이섀도	34200275	핸드케어	30500149

# 목표: 2016년 6월 1일 ~ 8월 31일까지 12개 자재에 대한 일별 판매량을 예측함
# 제공파일: sales_2015.csv 2015년 sales 데이터            test.csv  Test 데이터(제출용)
# sales_2016.csv 2016년 sales 데이터
# promotion.csv  행사정보데이터
# cupon_date.xlsx  쿠폰행사 정보데이터
# rival_event.xlsx  경쟁사행사 정보데이터

# file read
suppressMessages(library(tidyverse))
suppressMessages(library(data.table))
suppressMessages(library(Hmisc))
suppressMessages(library(lubridate))

suppressMessages(library(caret))
suppressMessages(library(rpart))
suppressMessages(library(randomForest))
suppressMessages(library(gbm))
suppressMessages(library(pls))


df.sales_2015 <- fread("sales_2015.csv", data.table=F)
df.sales_2016 <- fread("sales_2016.csv", data.table=F)
df.promotion <-  fread("promotion.csv", data.table=F)
df.test <-  fread("test.csv", data.table=F)

# 1. 자재 코드 12개에 대한 데이터 셋 만들기
df.sales_2015 <- df.sales_2015 %>% 
  filter (자재코드 %in% c('32900539','30400512','34200266','31500200','32800575','32500391','34200131','30400521','32900535','32400198','34200275','30500149'))
df.sales_2016 <- df.sales_2016 %>% 
  filter (자재코드 %in% c('32900539','30400512','34200266','31500200','32800575','32500391','34200131','30400521','32900535','32400198','34200275','30500149'))
df.test <- df.test %>% 
  filter (자재코드 %in% c('32900539','30400512','34200266','31500200','32800575','32500391','34200131','30400521','32900535','32400198','34200275','30500149'))
df.promotion <- df.promotion %>% 
  filter (자재코드 %in% c('32900539','30400512','34200266','31500200','32800575','32500391','34200131','30400521','32900535','32400198','34200275','30500149'))

###### 컬럼 제거 : 디폴트 
# 분석대상, BM 
df.sales_2015 <- df.sales_2015 %>% 
  select (-c(분석대상, BM))

df.sales_2016 <- df.sales_2016 %>% 
  select (-c(분석대상, BM))

df.test <- df.test %>% 
  select (-c(분석대상, BM))

# 컬럼 네임 영어로 변경
# [1] "년월일"       "할인행사여부" "브랜드"       "라인"         "유형"         "자재코드"     "판매수량"    
# [8] "매출액"
df.sales_2015 <- df.sales_2015 %>% 
  rename(
    yyyymmdd = 년월일, 
    promotion_yn = 할인행사여부,
    brand = 브랜드,
    line = 라인,
    type = 유형,
    matirial_code = 자재코드,
    sales_cnt = 판매수량,
    revenue = 매출액
  )

df.sales_2016 <- df.sales_2016 %>% 
  rename(
    yyyymmdd = 년월일, 
    promotion_yn = 할인행사여부,
    brand = 브랜드,
    line = 라인,
    type = 유형,
    matirial_code = 자재코드,
    sales_cnt = 판매수량,
    revenue = 매출액
  )

df.sales <- rbind(df.sales_2015, df.sales_2016)
rm(df.sales_2015)
rm(df.sales_2016)

df.test <- df.test %>% 
  rename(
    yyyymmdd = 년월일, 
    promotion_yn = 할인행사여부,
    brand = 브랜드,
    line = 라인,
    type = 유형,
    matirial_code = 자재코드
  )

df.promotion <- df.promotion %>% 
  rename(
    info = 프로모션정보, 
    start_day = 프로모션시작일,
    end_day = 프로모션종료일,
    contents = 할인내용,
    matirial_code = 자재코드
  )

###### 날짜 관련 파생 컬럼 추가
# 날짜 
df.sales$d_yyyymmdd <- make_date(substr(df.sales$yyyymmdd,1,4),
          substr(df.sales$yyyymmdd,5,6),
          substr(df.sales$yyyymmdd,7,8))

df.test$d_yyyymmdd <- make_date(substr(df.test$yyyymmdd,1,4),
                                 substr(df.test$yyyymmdd,5,6),
                                 substr(df.test$yyyymmdd,7,8))

# 요일
df.sales$wday <- wday(df.sales$d_yyyymmdd) # 1 : 일요일 , 7 : 토요일
df.test$wday <- wday(df.test$d_yyyymmdd) # 1 : 일요일 , 7 : 토요일

# 년
df.sales$year <- year(df.sales$d_yyyymmdd) 
df.test$year <- year(df.test$d_yyyymmdd) 

# 월
df.sales$month <- month(df.sales$d_yyyymmdd) 
df.test$month <- month(df.test$d_yyyymmdd) 

# 공휴일
df.holydays <- read.csv('holydays.csv', stringsAsFactors = F)

getHolydays <- function (x) {
  for (i in 1:NROW(df.holydays)) {
    if (x == df.holydays$locdate[i]) {
      return (df.holydays$dateName[i])
    }
  }
  return ("Not Holyday")
}

for ( idx in 1:NROW(df.sales)) {
    df.sales$holyday[idx] <- getHolydays(df.sales$yyyymmdd[idx])  
}
for ( idx in 1:NROW(df.test)) {
  df.test$holyday[idx] <- getHolydays(df.test$yyyymmdd[idx])  
}


###### 타 데이터 컬럼 추가
# 판촉 내용 컬럼 추가 (promotion_contents)
getPromotionInfo <- function (x, y) {
  df.temp <- df.promotion %>% 
    filter(matirial_code == x,
           y >= start_day,
           y <= end_day
           ) %>% 
    select(contents) %>% 
    slice(1:1)
  df.temp$contents[1]
}

for(idx  in 1:NROW(df.sales)) {
  df.sales$promotion_contents[idx] = getPromotionInfo(df.sales$matirial_code[idx],df.sales$yyyymmdd[idx])
}
for(idx  in 1:NROW(df.test)) {
  df.test$promotion_contents[idx] = getPromotionInfo(df.test$matirial_code[idx],df.test$yyyymmdd[idx])
}

##### 컬럼 추가 제거 : 변하지 않는 컬럼 제거
# 자재코드의 브랜드, 라인, 타입이 변하는 지 확인 
df.sales %>% 
  group_by(matirial_code) %>% 
  summarise (n_distinct(brand), n_distinct(line), n_distinct(type))
# 타입은 변하지 않으므로 제거
# 브랜드 , 라인은 변하므로, 매출에 영향을 줄 수 있다. 

df.sales <- df.sales %>% 
  select (-c(type))

df.test <- df.test %>% 
  select (-c(type))


# 해당일 경쟁사 프로모션 갯수 컬럼 추가: c_promotion_cnt
df.competitor <- read.csv('competitor.csv', stringsAsFactors = F)
df.competitor <- melt(df.competitor, id.vars=1)
str(df.competitor)
df.competitor <-df.competitor %>% 
  rename(c_company = 회사, 
         yyyymm = variable,
         day_range = value)

df.competitor$day_range <- str_trim(df.competitor$day_range)

# NA, 공백 데이터 삭제
df.competitor <-df.competitor %>% 
  filter(!is.na(day_range))
dim(df.competitor)
df.competitor <- df.competitor %>% 
  filter(day_range != "")
dim(df.competitor)

# 년, 월, 시작일, 종료일 컬럼 추가
df.competitor$year <- substr(df.competitor$yyyymm,2,5)
df.competitor$startday <- str_trim(str_split_fixed(df.competitor$day_range, "~",2)[,1])
df.competitor$month <- str_trim(str_split_fixed(df.competitor$startday,"/",2)[,1])

# 시작/종료 일자에는 일자(day)만 추출하여 넣기
df.competitor$startday <- str_trim(str_split_fixed(df.competitor$startday, "/",2)[,2])
df.competitor$startday <- str_trim(str_split_fixed(df.competitor$startday, "\\(",2)[,1])
df.competitor$endday <- str_trim(str_split_fixed(df.competitor$day_range, "~",2)[,2])
df.competitor$endday <- ifelse(str_trim(str_split_fixed(df.competitor$endday, "/",2)[,2]) == "",
                                df.competitor$endday,
                                str_trim(str_split_fixed(df.competitor$endday, "/",2)[,2]))
df.competitor$endday <- str_trim(str_split_fixed(df.competitor$endday, "\\(",2)[,1])

# 최종적으로 startdate, enddate 날짜 컬럼 추가
df.competitor <- df.competitor %>% 
  mutate(startdate = make_date(year,month,startday),
         enddate = make_date(year,month,endday))

# 잘 되었나 확인 
df.competitor %>% 
  select (day_range, startdate, enddate )

table(df.competitor$c_company)
# df.sales, df.test 에 컬럼 추가
# c_promotion_cnt : 해당일 경쟁사 프로모션 갯수 합계 
getCompetitorPromotionCount <- function (x) {
  df.temp <- df.competitor %>% 
    filter( between(x, startdate, enddate) ) 
  NROW(df.temp)  
}
for(idx  in 1:NROW(df.sales)) {
  df.sales$c_promotion_cnt[idx] = getCompetitorPromotionCount(df.sales$d_yyyymmdd[idx])
}

for(idx  in 1:NROW(df.test)) {
  df.test$c_promotion_cnt[idx] = getCompetitorPromotionCount(df.test$d_yyyymmdd[idx])
}


############################### revenue 를 삭제하고, sales_cnt 로 예측 실시
###### 컬럼 삭제
# revenue: salse_cnt  와 중복되는 종속 변수
# yyyymmdd,d_yyyymmdd : 날짜는 독립변수가 아님
# year : test 데이터는 2016년 밖에 없다. (년도에 따른 변화는 없는 걸로)

df.sales <- df.sales %>% 
  select (-revenue,-yyyymmdd,-d_yyyymmdd,-year)
df.test <- df.test %>% 
  select (-yyyymmdd,-d_yyyymmdd,-year)


str(df.test)
###### 컬럼 정리
# promotion : 비할인행사  -> FALSE, 할인행사 TRUE 로 이원화 하자
df.sales$promotion <- is.na(str_locate(df.sales$promotion_yn,"비할인행사")[,1])
df.sales <- df.sales %>% 
  select (-promotion_yn)
df.test$promotion <- is.na(str_locate(df.test$promotion_yn,"비할인행사")[,1])
df.test <- df.test %>% 
  select (-promotion_yn)

# brand : 범주형으로 변경
setdiff(df.test$brand, df.sales$brand)
lvl_brand <- rownames(table(df.sales$brand))
# line: 범주형으로 변경
setdiff(df.test$line, df.sales$line)
lvl_line <- rownames(table(df.sales$line))
# matirial_code : 범주형으로 변경
setdiff(df.test$matirial_code, df.sales$matirial_code)
lvl_matirial_code <- rownames(table(df.sales$matirial_code))
# wday : 범주형으로 변경
setdiff(df.test$wday, df.sales$wday)
lvl_wday <- rownames(table(df.sales$wday))
# month : 범주형으로 변경 (월별로 매출이 다를 수 있다. 5월 최성수기 , 8월 비수기 )
setdiff(df.test$month, df.sales$month)
lvl_month <- rownames(table(df.sales$month))
# 5개 컬럼 범주화 
df.sales <- df.sales %>% 
  mutate(brand = factor(brand, levels = lvl_brand),
         line = factor(line, levels = lvl_line),
         matirial_code = factor(matirial_code, levels = lvl_matirial_code),
         wday = factor(wday, levels = lvl_wday),
         month = factor(month, levels = lvl_month))
df.test <- df.test %>% 
  mutate(brand = factor(brand, levels = lvl_brand),
         line = factor(line, levels = lvl_line),
         matirial_code = factor(matirial_code, levels = lvl_matirial_code),
         wday = factor(wday, levels = lvl_wday),
         month = factor(month, levels = lvl_month))

# holyday : 범주형 -> Holyday , Not Holyday 로 이원화 하자 
df.sales$holyday <- df.sales$holyday != "Not Holyday"
df.test$holyday <- df.test$holyday != "Not Holyday"

# promotion_contents : 할인행사인 경우, 할인율 정보를 별도로 추출하자. 
df.sales$dc_rate <- ifelse(df.sales$promotion,substr(df.sales$promotion_contents,1,2),0)
df.test$dc_rate <- ifelse(df.test$promotion,substr(df.test$promotion_contents,1,2),0)
# 멤버십데이가 있다. 이건 50% ~ 30% 이다. 대충 50으로 하자 .
df.sales$dc_rate <- ifelse(df.sales$dc_rate == "TF",50,df.sales$dc_rate)
df.test$dc_rate <- ifelse(df.test$dc_rate == "TF",50,df.test$dc_rate)
# 썸머)본품증정1+1 -> 50% 이다.
df.test$dc_rate <-ifelse(df.test$dc_rate == "썸머",50,df.test$dc_rate)
df.sales$dc_rate <- as.numeric(df.sales$dc_rate)
df.test$dc_rate <- as.numeric(df.test$dc_rate)

#                      비할인 행사 인경우인데 10+10 같은 것이 있다. 이것은 event로 정의하자 
df.sales$event <- ifelse(df.sales$promotion,FALSE,
       ifelse(is.na(df.sales$promotion_contents),FALSE,TRUE))
df.test$event <- ifelse(df.test$promotion,FALSE,
                         ifelse(is.na(df.test$promotion_contents),FALSE,TRUE))

# c_promotion_cnt : 수치형 유지 : 경쟁사가 할인을 많이 할 수록 ... 매출 영향 
 
# promotion_content 컬럼은 dc_rate와 event로 분화되었다. 
df.sales <-  df.sales %>% 
  select (-promotion_contents)
df.test <-  df.test %>% 
  select (-promotion_contents)


# 데이터 정리 완료 
str(df.sales)
str(df.test)
write.csv(df.sales, 'df_sales.csv', row.names = F, quote = F)
write.csv(df.test, 'df_test.csv', row.names = F, quote = F)

#######################################################################################################
# 모델 적용 
# 종속변수 : 수치형 (revenue)
# 독립변수 : 범주형, 수치형 (brand,line,matirial_code,wday,month,holyday,c_promotion_cnt,promotion,dc_rate,event)
rm(list=ls())

# 모델 성능 기준 
mae <- function(yi, yhat_i){
  mean(abs(yi - yhat_i))
}

df.train <- read.csv( 'df_sales.csv', header = TRUE, stringsAsFactors=F)
df.test <-  read.csv( 'df_test.csv', header = TRUE, stringsAsFactors=F)

# 결측치 확인 : 이상 없음. 
summary(df.train)
summary(df.test)


df.train %>%
  summarize_all(funs(length(which(is.na(.)))/length(.))) %>% 
  glimpse()

df.test %>%
  summarize_all(funs(length(which(is.na(.)))/length(.))) %>% 
  glimpse()

# 범주형 변경

# brand : 범주형
lvl_brand <- rownames(table(df.train$brand))
# line: 범주형으로 변경
lvl_line <- rownames(table(df.train$line))
# matirial_code : 범주형으로 변경
lvl_matirial_code <- rownames(table(df.train$matirial_code))
# wday : 범주형으로 변경
lvl_wday <- rownames(table(df.train$wday))
# month : 범주형으로 변경
lvl_month <- rownames(table(df.train$month))
# holyday : 범주형 (True/False)
# c_promotion_cnt : 수치형 
# promotion : 범주형 (True, False)
# dc_rate : 수치형
# event : 범주형 (True/False)

# 5개 컬럼 범주화 
df.train <- df.train %>% 
  mutate(brand = factor(brand, levels = lvl_brand),
         line = factor(line, levels = lvl_line),
         matirial_code = factor(matirial_code, levels = lvl_matirial_code),
         wday = factor(wday, levels = lvl_wday),
         month = factor(month, levels = lvl_month) )
df.test <- df.test %>% 
  mutate(brand = factor(brand, levels = lvl_brand),
         line = factor(line, levels = lvl_line),
         matirial_code = factor(matirial_code, levels = lvl_matirial_code),
         wday = factor(wday, levels = lvl_wday),
         month = factor(month, levels = lvl_month))



# 훈련, 검증, 테스트셋의 구분
set.seed(20181119)
ind <- createDataPartition(df.train$sales_cnt, p = .7, list = FALSE)
training <- df.train[ind,]
validation <- df.train[-ind,]

# 모델 생성 
# A. 회귀 모형
df_lm_full <- lm(sales_cnt ~ ., data=training)
summary(df_lm_full)

# stemwise 절차를 통한 변수 선택
df_step <- MASS::stepAIC(df_lm_full, scope = list(upper = ~ ., lower = ~1))
df_step
anova(df_step)
summary(df_step)
length(coef(df_step))
length(coef(df_lm_full))


# 예측정확도 지표
y_obs <- validation$sales_cnt
yhat_lm <- predict(df_lm_full, newdata=validation)
yhat_step <- predict(df_step, newdata=validation)
mae(y_obs, yhat_lm)
mae(y_obs, yhat_step)


# B. 나무모형
df_tr <- rpart(sales_cnt ~ ., data = training)
df_tr
yhat_tr <- predict(df_tr, validation)
mae(y_obs, yhat_tr)

# C. 랜덤포레스트
set.seed(20181119)
df_rf <- randomForest(sales_cnt ~ ., training)
plot (df_rf)
importance(df_rf)
varImpPlot(df_rf)

yhat_rf <- predict(df_rf, newdata=validation)
mae(y_obs, yhat_rf)

# D. 부스팅
set.seed(20181119)

# logical -> factor 
training$holyday <- as.factor(training$holyday)
training$promotion <- as.factor(training$holyday)
training$event <- as.factor(training$event)
validation$holyday <- as.factor(validation$holyday)
validation$promotion <- as.factor(validation$holyday)
validation$event <- as.factor(validation$event)

df_gbm <- gbm(sales_cnt ~ ., data=training,distribution="gaussian",
              n.trees=1000, cv.folds=3, verbose=TRUE)


(best_iter <- gbm.perf(df_gbm, method="cv"))

yhat_gbm <- predict(df_gbm, n.trees=best_iter,
                    newdata=validation)

mae(y_obs, yhat_gbm)



mae(y_obs, yhat_lm)
mae(y_obs, yhat_step)
mae(y_obs, yhat_tr)
mae(y_obs, yhat_rf)
mae(y_obs, yhat_gbm)

cor(y_obs, yhat_rf)
# 랜덤 포레스트가 가장 적합하다. 
# 테스트 데이터 예측 
yhat_rf_test <- predict(df_rf, newdata=df.test)


# 제출 - 기존 컬럼 유지
df.test_report <-  fread("test.csv", data.table=F)
str(df.test_report)
df.test_report <- df.test_report %>% 
  filter (자재코드 %in% c('32900539','30400512','34200266','31500200','32800575','32500391','34200131','30400521','32900535','32400198','34200275','30500149'))

write.csv(
  cbind(df.test_report, 판매량 = yhat_rf_test), 'test_result.csv', row.names = F, quote =  F)
