import numpy as np
from datetime import datetime, timedelta
import dateutil.parser
import h5py
import csv
import os


stride = 10
time_size = 20

def create_hdf5(in_dir, out_dir):
    #load line definitions
    lines_dic = {}
    for i,el in enumerate(list(csv.reader(open('lines_def.txt', 'r')))):
        lines_dic[el[0]] = i
    
    files = [os.path.join(dp, f) for dp, _, filenames in os.walk(in_dir) for f in filenames \
                                        if os.path.splitext(f)[1] == '.csv']
    out_path_txt = out_dir+'/list_hdf5.txt'
    if os.path.exists(out_path_txt): os.remove(out_path_txt)
    lat_m, long_m = -22.9083, -43.1964 #center of RJ coords
    day_m = 3600.*12. #mid_day in seconds
    for fp in files:
        data = list(csv.DictReader(open(fp, 'r'), delimiter=';'))
        if data[0]['Line'] in lines_dic: #only goes if the line is in the definition
            data_size = len(data)
            if len(range(time_size,data_size,stride))>0:
                i=0
                data4D = np.zeros((len(range(time_size,data_size,stride)),3,1,time_size),dtype=np.float32)
                label2D = np.zeros((len(range(time_size,data_size,stride)),1),dtype=np.float32)
                for j in range(time_size,data_size,stride):
                    print ('batch',j//stride,'of',data_size//stride)
                    for k in range(time_size):
                        item = data[j-k]
                        timestamp = dateutil.parser.parse(item['TimeStamp'][:10]+' '+item['TimeStamp'][10:]) #the start date starts at 0 minutes of the hour
                        data4D[i,0,0,k] = (float(item['LatitudePoint'])-lat_m)/0.1#/0.5 #divide by 0.1 in order to get larger numbers
                        data4D[i,1,0,k] = (float(item['LongitudePoint'])-long_m)/0.1#/0.5  #divide by 0.1 in order to get larger numbers
                        data4D[i,2,0,k] = ((timestamp.hour*3600+timestamp.minute*60+timestamp.second)-day_m)/(2*day_m) #subtract mean sec day and divide by day total seconds. This normalization between [-0.5,0.5]
                    
                    label2D[i,0] = lines_dic[item['Line']] #Get only the last ground_truth
                        
                    i=i+1
                #save as hdf5
                with h5py.File(out_dir+fp.replace(in_dir,'').replace('.csv','.h5'), 'w') as f:
                    f.create_dataset('data', data=data4D, compression="gzip")
                    f.create_dataset('label', data=label2D)
                with open(out_path_txt, 'a') as f:
                    f.write('/workspace/BusGps/caffe/'+out_dir+fp.replace(in_dir,'').replace('.csv','.h5')+'\n')
        else:
            print ('line not found:',data[0]['Line'])
            pass

train_in_dir = 'spliteddata'
train_out_dir = 'hdf5'
#train_in_dir = '/home/rfn/NYU/BusRio/Splitted_Data/'
#train_out_dir = '/home/rfn/NYU/BusRio/hdf5/'

create_hdf5(train_in_dir, train_out_dir)
