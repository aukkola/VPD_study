

import glob
import sys 
import os
import xarray as xr


#Calculate 3-hourly climatology for 1970-1999

#Data path
data_path="/g/data/w97/Shared_data/AWAP_3h_v1/"

variables=['Qair', "Tair"]


for v in variables:
    
    print(v)
    
    #Find files 

    #1970s
    files_70s=glob.glob(str(data_path + '/' + v + '/*197*.nc'))
    all_files=files_70s

    #1980s
    files_80s=glob.glob(str(data_path + '/' + v + '/*198*.nc'))
    all_files.extend(files_80s)

    #1990s
    files_90s=glob.glob(str(data_path + '/' + v + '/*199*.nc'))
    all_files.extend(files_90s)



    #Calculate mean Qair and temperature during 1970-1999

    #Open data handle
    ds = xr.open_mfdataset(all_files)

    #Get data (not exatcly sure what this does)
    #got the code from here: https://stackoverflow.com/questions/55997826/averaging-2-decades-of-data-on-6-hourly-timestep-using-netcdf-data-and-python
    ds['hourofyear'] = xr.DataArray(ds.indexes['time'].strftime('%m-%d %H'), coords=ds.time.coords)
    climatology = ds.groupby('hourofyear').mean('time')



    ### Write to file ###
    outdir=str(data_path + "/../" + v + "_climatology/")
    os.system("mkdir -p " + outdir)

    outfile=str(outdir + "/AWAP." + v + ".3hr.climatology_1970_1999.nc")

    #Rename data variable
    #climatology.name = v
    
    #5pm
    #Write to file
    #ncdat.load().to_netcdf('test_faster.nc')
    
    climatology.to_netcdf(outfile, format='NETCDF4', 
                   encoding={v:{
                             'shuffle':True,
                             'chunksizes':[12, 681, 40],
                             'zlib':True,
                             'complevel':5}
                             })




