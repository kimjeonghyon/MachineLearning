#!/usr/bin/env python
# coding: utf-8

import os
from datetime import datetime
import time
import webbrowser
import enum
from selenium import webdriver
from bs4 import BeautifulSoup
import numpy as np


fromDt = '20200101'
#toDt = '20200101'
#yyyymm = '202001'
web_id = 'bitest15'
web_pass = 'P@ssword01'

browser = webdriver.Chrome(r"/Users/jeonghyonkim/Documents/Dev/chromedriver")

browser.get('https://dt.tmoney.co.kr/')
time.sleep(3)
browser.find_element_by_name('id').send_keys(web_id)
browser.find_element_by_name('pd').send_keys(web_pass)
browser.find_element_by_xpath('//*[@id="login"]/div[2]/div/div[2]/a/img').click()


browser.get('https://dt.tmoney.co.kr/com/main.do?PID=BDPM015001001')
time.sleep(3)


# browser.find_element_by_xpath('//*[@id="LblockSearch"]/div/div/div/form/table/tbody/tr/td/input').click()


browser.find_element_by_name('btnSearch').click()
print('btn clicked!')

time.sleep(20)
browser.close()

print('success!')
