import csv
import os.path

in_dir = 'rawdata/'
output_dir = 'spliteddata/'
#data_rows = csv.reader(open(data_file_path, 'r'), delimiter=',')


files = [os.path.join(dp, f) for dp, _, filenames in os.walk(in_dir) for f in filenames]

for fp in files:
    data_rows = csv.DictReader(open(fp, 'r'), delimiter=',')
    for row in data_rows:
        # key : Line, Bus, Year, Month, DayMonth
        #key = r[0]+'_'+r[2]+'_'+r[5][:4]+'_'+r[5][4:6]+'_'+r[5][6:8]
        #["ROT_NO,ROT_ID,VEHC_ID,LATTD,LONGTD,PASS_DTIME,RUN_DEPART_DTIME,PASS_DIST,STA_ID,STD_ORD\n"]
        out_file_name = row['ROT_NO']+'_'+row['VEHC_ID']+'_'+row['PASS_DTIME'][:4]+'_'+row['PASS_DTIME'][4:6]+'_'+row['PASS_DTIME'][6:8]+'.csv'
        write_header=False
        if not os.path.isfile(output_dir+'/'+out_file_name): #write headers if file does not exists
            write_header=True
        with open(output_dir+'/'+out_file_name,'a') as f:
            csvfile = csv.writer(f, delimiter=';', lineterminator='\n')
            if write_header:
                csvfile.writerow(row.keys())
            csvfile.writerow(row.values())
            
            
print ('finished\n')
