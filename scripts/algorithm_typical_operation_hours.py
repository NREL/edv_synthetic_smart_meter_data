import pandas as pd
import numpy as np
from scipy.signal import savgol_filter
import datetime

################################################################
# inputs
################################################################
timeseries_load = pd.read_csv("./sample_input_file.csv") #TODO: consider of not creating csv and just directly read XML via python
time_interval = 1 #TODO: change it to detect based on input file
list_hist_start_final = []
list_hist_stop_final = []
numberofvaluesinarray = int(24/time_interval)

for column in timeseries_load:
    
    ################################################################
    # read daily profiles
    ################################################################
    time_series_96 = timeseries_load[column].values

    ################################################################
    # apply G-S filter
    ################################################################
    time_series_96_gaf = savgol_filter(time_series_96, 3, 1)

    ################################################################
    # start and stop time threshold definition (currently both thresholds are defined as the same)
    ################################################################
    thre_start = (np.percentile(time_series_96_gaf, 97.5) - np.percentile(time_series_96_gaf, 2.5))*0.5 + time_series_96_gaf.min()
    thre_stop = (np.percentile(time_series_96_gaf, 97.5) - np.percentile(time_series_96_gaf, 2.5))*0.5 + time_series_96_gaf.min()
    list_hist_start = []
    
    ################################################################
    # start time detection
    ################################################################
    for i in range(0,int(numberofvaluesinarray/2)+1):
                
        ### if (power at current timestep is less than thre_start) & (power at next timestep is larger than thre_start) & (if power at next timestep is closer to thre_start)
        ### then add next timestep in the list
        if (time_series_96_gaf[i] < thre_start) and (thre_start < time_series_96_gaf[i+1]) and (abs(thre_start - time_series_96_gaf[i]) > abs(thre_start - time_series_96_gaf[i+1])):
            list_hist_start = list_hist_start + [i+1]
            
        ### if (power at current timestep is less than thre_start) & (power at next timestep is larger than thre_start) & (if power at current timestep is closer to thre_start)
        ### then add current timestep in the list
        if (time_series_96_gaf[i] < thre_start) and (thre_start < time_series_96_gaf[i+1]) and (abs(thre_start - time_series_96_gaf[i]) <= abs(thre_start - time_series_96_gaf[i+1])):
            list_hist_start = list_hist_start + [i]
        
    
    if len(list_hist_start) != 1:
        for i in range(int(numberofvaluesinarray/2)-2,numberofvaluesinarray-1):
        
            ### if (power at current timestep is less than thre_start) & (power at next timestep is larger than thre_start) & (if power at next timestep is closer to thre_start)
            ### then add next timestep in the list
            if (time_series_96_gaf[i] < thre_start) and (thre_start < time_series_96_gaf[i+1]) and (abs(thre_start - time_series_96_gaf[i]) > abs(thre_start - time_series_96_gaf[i+1])):
                list_hist_start = list_hist_start + [i+1]

            ### if (power at current timestep is less than thre_start) & (power at next timestep is larger than thre_start) & (if power at current timestep is closer to thre_start)
            ### then add current timestep in the list
            if (time_series_96_gaf[i] < thre_start) and (thre_start < time_series_96_gaf[i+1]) and (abs(thre_start - time_series_96_gaf[i]) <= abs(thre_start - time_series_96_gaf[i+1])):
                list_hist_start = list_hist_start + [i]
                        
        ### if start time was not found from above, add 0 in the list
        if len(list_hist_start) != 1:
            list_hist_start = [0]

    ################################################################
    # stop time detection
    ################################################################
    list_hist_stop = []
    for i in range(int(numberofvaluesinarray/2)-2,numberofvaluesinarray-1):
        
        ### is condidering second half of day (range(48,95)) appropriate?
        
        ### if (power at next timestep is less than thre_stop) & (power at current timestep is larger than thre_stop) & (if power at next timestep is closer to thre_stop)
        ### then add next timestep in the list
        if (time_series_96_gaf[i+1] < thre_stop) and\
                (thre_stop < time_series_96_gaf[i]) and\
                (abs(thre_stop - time_series_96_gaf[i]) > abs(thre_stop - time_series_96_gaf[i+1])):
            list_hist_stop = list_hist_stop + [i+1]
            
        ### if (power at next timestep is less than thre_stop) & (power at current timestep is larger than thre_stop) & (if power at current timestep is closer to thre_stop)
        ### then add current timestep in the list
        if (time_series_96_gaf[i+1] < thre_stop) and (thre_stop < time_series_96_gaf[i]) and (abs(thre_stop - time_series_96_gaf[i]) <= abs(thre_stop - time_series_96_gaf[i+1])):
            list_hist_stop = list_hist_stop + [i]
            
    if len(list_hist_stop) != 1:
        for i in range(0,int(numberofvaluesinarray/2)+1):
        
            ### if (power at next timestep is less than thre_stop) & (power at current timestep is larger than thre_stop) & (if power at next timestep is closer to thre_stop)
            ### then add next timestep in the list
            if (time_series_96_gaf[i+1] < thre_stop) and\
                    (thre_stop < time_series_96_gaf[i]) and\
                    (abs(thre_stop - time_series_96_gaf[i]) > abs(thre_stop - time_series_96_gaf[i+1])):
                list_hist_stop = list_hist_stop + [i+1]

            ### if (power at next timestep is less than thre_stop) & (power at current timestep is larger than thre_stop) & (if power at current timestep is closer to thre_stop)
            ### then add current timestep in the list
            if (time_series_96_gaf[i+1] < thre_stop) and (thre_stop < time_series_96_gaf[i]) and (abs(thre_stop - time_series_96_gaf[i]) <= abs(thre_stop - time_series_96_gaf[i+1])):
                list_hist_stop = list_hist_stop + [i]
                        
        ### if start time was not found from above, add 0 in the list
        if len(list_hist_stop) != 1:
            list_hist_stop = [24]
    
    ################################################################
    # add start/stop time results separately into one single list
    ################################################################
    list_hist_start_final = list_hist_start_final + list_hist_start
    list_hist_stop_final = list_hist_stop_final + list_hist_stop
    
 
################################################################
# filter list that detected both start and stop times
################################################################ 
list_combined = [[a,b] for a,b in zip(list_hist_start_final,list_hist_stop_final) if a*b != 0]