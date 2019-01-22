
   

suppressWarnings({
  library(glue)
  library(XML)
  library(stringr)
})

api.key <- '%2BKf44ySD10XvRvH65za55z5v%2BU3cCcLRn2FEHSjhxnDNGVSCiwZ43WzY1vutsvWpLEhBadAuY0tmYEaORuvfrg%3D%3D'
url.format <- 
  'http://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo?ServiceKey={key}&solYear={year}&solMonth={month}'

holiday.request <- function(key, year, month) glue(url.format)

# request and read data : year 2015
datalist = list()

cnt <- 0
for(m in 1:12){
  data <- xmlToList(holiday.request(api.key, 2015, str_pad(m, 2, pad=0)))
  items <- data$body$items
  for(item in items){
    cnt <- cnt + 1
    if(item$isHoliday == 'Y') {
      print(paste(item$dateName, item$locdate, sep=' : '))
      datalist[[cnt]] <- data.frame(dateName=item$dateName, locdate=item$locdate)
    }
  }
}

df.holydays_2015 = do.call(rbind, datalist)


datalist = list()

cnt <- 0
for(m in 1:12){
  data <- xmlToList(holiday.request(api.key, 2016, str_pad(m, 2, pad=0)))
  items <- data$body$items
  for(item in items){
    cnt <- cnt + 1
    if(item$isHoliday == 'Y') {
      print(paste(item$dateName, item$locdate, sep=' : '))
      datalist[[cnt]] <- data.frame(dateName=item$dateName, locdate=item$locdate)
    }
  }
}

df.holydays_2016 = do.call(rbind, datalist)


df.holydays <- rbind(df.holydays_2015, df.holydays_2016)

write.csv(df.holydays, 'holydays.csv')
