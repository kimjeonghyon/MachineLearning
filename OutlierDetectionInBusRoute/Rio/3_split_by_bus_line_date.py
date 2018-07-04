import csv
import os.path

in_dir = 'rawdata/'
output_dir = 'spliteddata/'
#data_rows = csv.reader(open(data_file_path, 'r'), delimiter=',')


files = [os.path.join(dp, f) for dp, _, filenames in os.walk(in_dir) for f in filenames]

for fp in files:
    if fp.endswith("with_speed") :
        data_rows = csv.DictReader(open(fp, 'r'), delimiter=',')
        for row in data_rows:
            out_file_name = row['Line']+'_'+row['Bus']+'_'+row['Year']+'_'+row['Month']+'_'+row['DayMonth']+'.csv'
            write_header=False
            if not os.path.isfile(output_dir+'/'+out_file_name): #write headers if file does not exists
                write_header=True
            with open(output_dir+'/'+out_file_name,'a') as f:
                csvfile = csv.writer(f, delimiter=';', lineterminator='\n')
                if write_header:
                    csvfile.writerow(row.keys())
                csvfile.writerow(row.values())
				
            
print ('finished\n')
