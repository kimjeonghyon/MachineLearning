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



# Prediction Hammer Price of Apartment (아파트 낙찰가 예측) - 2019년
## 목적
아파트 경락 자금 대출 시 낙찰가를 예측하여 대출 기준 값으로 사용한다.

## 분석 방법
R

원본 데이터 : 아파트 입찰 정보, 대법원 등기 정보, 아파트 전입 관련 정보 등

## 데이콘 데이터 분석 경진 대회 출품작 (50위?)
https://dacon.io/cpt3



# Prediction Sales Count of Store (가게 매출 예측) - 2019
## 목적
미래 특정 날짜의 판매량을 매측한다.

## 분석 방법
R

원본 데이터 : 판매 이력 정보, 경쟁사 판촉 정보, 자사 판촉 정보 등.
