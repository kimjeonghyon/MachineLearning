
# Apple ML Compute Tensorflow 2.4 Performance Test - 2020
## 목적
OS Big Sur와 XCode 12를 설치하면
Mac에서 GPU로 딥러닝을 할 수 있게 되었다. 
과연, 성능은 어느 정도 일까?

## mbp 2019 16 inch vs nvidia gtx 1660 super vs google colab gpu


### Macbook 2019 16 inch 
2.6GHz 6코어 Intel Core i7(최대 4.5GHz Turbo Boost, 12MB 공유 L3 캐시)
16GB 2666MHz DDR4 온보드 메모리
AMD Radeon Pro 5300M

### Windows PC 
Intel 2코어 Pentium G5400 (3.70 GHz, 4 MB Intel® Smart Cache)ㅁ
16GB 2666MHz DDR4 메모리
MSI GTX 1660 SUPER 게이밍 X D6 6GB 트윈프로져7 FB


### Google Colab GPU 
Intel 2코어 Pentium G5400 (3.70 GHz, 4 MB Intel® Smart Cache)ㅁ
16GB 2666MHz DDR4 메모리
MSI GTX 1660 SUPER 게이밍 X D6 6GB 트윈프로져7 FB


## 소스 
MachineLearingTips/CNN_BM.ipynb


MNIST 분류 성능 실험

CNN 신경망 모델 사용

## 실험 결과
MachineLearingTips/gpu_bm_test


mbp 16 inch (2019) : 29 seconds / epoch

gtx 1660 super : 3 seconds / epoch

colab gpu : 3 seconds / epoch


맥북 프로의 GPU인 라데온 프로 5300M의 성능은 

딥러닝을 하기에는 많이 부족한 모습을 보여주었다. 


# 웹 화면 조회 봇- 2020
## 목적

다음 작업 자동화 

웹브라우저로 특정 웹사이트에 접속
아이디, 패스워드 입력
화면 메뉴 클릭
조회 조건 입력
검색 버튼 클릭
웹 브라우저 종료


## 시스템 구조
selenium : 웹 드라이버 구동, 크롬 드라이버 사용
BeautifulSoup : HTML parsing

## 소스 
MachineLearingTips/web_monitor.py


# Machine Leaerning Service Deployment - REST API - 2020
## 목적
머신러닝 모델을 REST API로 서비스 한다.

## 시스템 구조
Python - 개발 언어
Flask - 웹 개발 프레임워크
gunicorn - 웹 컨테이너

예시 모델 : 데이콘 퇴근시간 버스승차인원 예측 모델 경진대회 코드 참조
(https://dacon.io/competitions/official/229255/codeshare/709?page=1&dtype=recent&ptype=pub)

## 위치
ml_api

# Prediction Sales Count of Store (가게 매출 예측) - 2019
## 목적
미래 특정 날짜의 판매량을 매측한다.

## 분석 방법
R

원본 데이터 : 판매 이력 정보, 경쟁사 판촉 정보, 자사 판촉 정보 등.


# Prediction Hammer Price of Apartment (아파트 낙찰가 예측) - 2019년
## 목적
아파트 경락 자금 대출 시 낙찰가를 예측하여 대출 기준 값으로 사용한다.

## 분석 방법
R

원본 데이터 : 아파트 입찰 정보, 대법원 등기 정보, 아파트 전입 관련 정보 등

## 데이콘 데이터 분석 경진 대회 출품작 (50위?)
https://dacon.io/cpt3

## 위치
PredictionOfHammerPrice




# Outlier Detection in Bus Route (버스 노선 이상 탐지 ) - 2018년
## 목적

버스가 정시성 있게 운행 되었는 지, 노선 이탈 , 출도착 지연이 없었는 지 이상 운행 패턴 감시

## 분석 방법

aws + caffe, python, pyCaffe

원본 데이터 : 버스 실시간 위치 정보

데이터 가공 : 

 일자, 노선, 차량별, 시간별 sorting

 상대 시간, 상대좌표 사용, 데이터 scaling

모델 : CNN (컨볼루셔널 뉴럴 네트워크)

훈련 및 평가 : 경사하강법, Relu, learing rate 조정

## 참고 사이트
https://github.com/rodrigonogueira4/BusData

## 위치
OutlierDetectionInBusRoute



# Taxi Demand Prediction (택시 수요 예측) - 2017년
## 목적
특정 위치의 시간, 날씨에 따른 택시 수요를 예측하는 서비스 제공

## 분석 방법
aws + pySpark, python scikit-learn

원본 데이터 : 일자별 택시 탑승 위치 정보 (뉴욕 택시)

데이터 가공 :

GPS 정보 그룹핑, 격자화

요일, 시간 정보 정규화

종속변수 : 탑승인원

독립변수 : 요일, 시간, 위치 등.

모델 : 랜덤포레스트회귀, kNN

훈련 및 평가 : 교차검증, R^2 (비율척도 관측치와 예측치의 상관도), RMSE

## 참고 사이트
http://sdaulton.github.io/TaxiPrediction/

