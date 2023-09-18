import pandas as pd
import numpy as np
from tqdm import tqdm
import requests
from requests.exceptions import ReadTimeout, ConnectTimeout
from multiprocessing import Pool
import re
import json


# 高德
def addr2code(geo):
    # parameters = {'address': geo, 'key': 'da4ad28b24dfe117687b257def1bca02'} #浩亮
    parameters = {'address': geo, 'key': '758b19e2580804d3238839e2eabfa59f'} #赟杰
    base = 'https://restapi.amap.com/v3/geocode/geo?parameters'
    loc = 0
    try:
        response = requests.get(base, parameters, timeout=2)
        if response.status_code == 200:
            answer = response.json()
            loc = answer['geocodes'][0]['location']
        else:
            loc='未查到'
    except:
        loc='未查到'
    return loc


def line(x):
    return x+'|'+addr2code(x)+'\n'


if __name__=='__main__':

    raw_addr = pd.read_csv('./raw_data/地址文本_20220728.txt', encoding='utf8')
    totaladdr = list(set(raw_addr.consign_address))

    with open('./output/gps_dict.json', 'r') as f:
        gps = json.load(f)

    extendaddr = [x for x in totaladdr if x not in gps]
    # print(len(extendaddr))

    f = open('./output/gps信息_20220728','w', encoding='utf8')
    p = Pool(10)
    for l in p.imap_unordered(line, tqdm(extendaddr)):
        f.write(l)
    p.close()
    p.join()
    f.close()
