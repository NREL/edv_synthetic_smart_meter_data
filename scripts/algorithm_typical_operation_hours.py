#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import os
import logging
import pandas as pd
import numpy as np
import datetime

from lxml import etree
from scipy.signal import savgol_filter

def typical_operation_hours(dir_path):
    try:
        if dir_path:
            for f in os.listdir(dir_path):
                bsync = os.path.join(dir_path, f)
                if bsync.endswith(".xml"):
                    print("processing", bsync)
                    ################################################################
                    # inputs
                    ################################################################
                    tree = etree.parse(bsync)
                    root = tree.getroot()
                    tag = root.tag
                    ns = tag.split('BuildingSync')[0]
                    years = {}

                    for e in root.iter(ns+"FieldName"):
                        if e.text == 'year': years[e.getnext().text] = []

                    for timeseries_data in root.iter(ns+"TimeSeries"):
                        for child in timeseries_data.getchildren():
                            for key in years.keys():
                                if child.tag == ns + 'StartTimestamp':
                                    if key == str(datetime.datetime.strptime(child.text, '%Y-%m-%d %H:%M').year):
                                        while(child.tag.replace(ns, '') != 'IntervalReading'):
                                            child = child.getnext()
                                        years[key].append(child.text)

                    time_interval = 1 #TODO: change it to detect based on input file
                    list_hist_start_final = []
                    list_hist_stop_final = []
                    number_of_values_in_array = int(24/time_interval)

                    for key in years.keys():
                        years[key] = np.reshape(np.array(years[key]).astype(np.float), (len(years[key])//24, 24))
                        for i in range(len(years[key])):
                            ################################################################
                            # apply S_G filter
                            ################################################################
                            time_series_96_gaf = savgol_filter(years[key][i], 3, 1)
                            ################################################################
                            # start and stop time threshold definition (currently both thresholds are defined as the same)
                            ################################################################
                            thre_start = (np.percentile(time_series_96_gaf, 97.5) - np.percentile(time_series_96_gaf, 2.5))*0.5 + time_series_96_gaf.min()
                            thre_stop = (np.percentile(time_series_96_gaf, 97.5) - np.percentile(time_series_96_gaf, 2.5))*0.5 + time_series_96_gaf.min()
                            list_hist_start = []

                            ################################################################
                            # start time detection
                            ################################################################
                            for i in range(0,int(number_of_values_in_array/2)+1):

                                ### if (power at current timestep is less than thre_start) & (power at next timestep is larger than thre_start) & (if power at next timestep is closer to thre_start)
                                ### then add next timestep in the list
                                if (time_series_96_gaf[i] < thre_start) and (thre_start < time_series_96_gaf[i+1]) and (abs(thre_start - time_series_96_gaf[i]) > abs(thre_start - time_series_96_gaf[i+1])):
                                    list_hist_start = list_hist_start + [i+1]

                                ### if (power at current timestep is less than thre_start) & (power at next timestep is larger than thre_start) & (if power at current timestep is closer to thre_start)
                                ### then add current timestep in the list
                                if (time_series_96_gaf[i] < thre_start) and (thre_start < time_series_96_gaf[i+1]) and (abs(thre_start - time_series_96_gaf[i]) <= abs(thre_start - time_series_96_gaf[i+1])):
                                    list_hist_start = list_hist_start + [i]

                            if len(list_hist_start) != 1:
                                for i in range(int(number_of_values_in_array/2)-2,number_of_values_in_array-1):

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
                            for i in range(int(number_of_values_in_array/2)-2,number_of_values_in_array-1):

                                ### is condidering second half of day (range(48,95)) appropriate?

                                ### if (power at next timestep is less than thre_stop) & (power at current timestep is larger than thre_stop) & (if power at next timestep is closer to thre_stop)
                                ### then add next timestep in the list
                                if (time_series_96_gaf[i+1] < thre_stop) and \
                                        (thre_stop < time_series_96_gaf[i]) and \
                                        (abs(thre_stop - time_series_96_gaf[i]) > abs(thre_stop - time_series_96_gaf[i+1])):
                                    list_hist_stop = list_hist_stop + [i+1]

                                ### if (power at next timestep is less than thre_stop) & (power at current timestep is larger than thre_stop) & (if power at current timestep is closer to thre_stop)
                                ### then add current timestep in the list
                                if (time_series_96_gaf[i+1] < thre_stop) and (thre_stop < time_series_96_gaf[i]) and (abs(thre_stop - time_series_96_gaf[i]) <= abs(thre_stop - time_series_96_gaf[i+1])):
                                    list_hist_stop = list_hist_stop + [i]

                            if len(list_hist_stop) != 1:
                                for i in range(0,int(number_of_values_in_array/2)+1):

                                    ### if (power at next timestep is less than thre_stop) & (power at current timestep is larger than thre_stop) & (if power at next timestep is closer to thre_stop)
                                    ### then add next timestep in the list
                                    if (time_series_96_gaf[i+1] < thre_stop) and \
                                            (thre_stop < time_series_96_gaf[i]) and \
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
    except Exception as e:
        logging.error(e)
    finally:
        print("Typical operation hours application completed.")

if __name__ == "__main__":
    try:
        if os.path.isdir(sys.argv[1]): typical_operation_hours(dir_path=sys.argv[1])
    except:
        logging.error("Incorrect measured data path")
