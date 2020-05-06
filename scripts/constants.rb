NAME_OF_OUTPUT_DIR = "BldgSync"
NAME_OF_INPUT_DIR = "inputs"

# EDITABLE
# Options include: ['default', 'bdgp-cz']
RUN_TYPE = "default"

# Options include: ['BDGP', 'SFDE'] - used by meta_to_buildingsync.rb
DATASOURCE = "BDGP"


# DO NOT EDIT
# Directory within edv-experiment-1 where raw data exists
RAW_DATA_DIR = "data/raw"

# Input file names for generate_xmls, assumed location depends on RUN_TYPE
DEFAULT_METADATA_FILE = "meta_open.csv"
BDGP_CZ_METADATA_FILE = "bdgp_with_climatezones_epw_ddy.csv"

WEATHER_DIR = "weather"

# Output location for generate_xmls task and name of summary file
GENERATE_DIR = "Bldg_Sync_Files"
GENERATE_SUMMARY_FILE_NAME = "meta_summary.csv"

# Output location for add_measured_data task
ADD_MEASURED_DIR = "Add_Measured_Data_Files"
# File used for source of timeseries data, regardless of RUN_TYPE
TIMESERIES_DATA_FILE = "temp_open_utc.csv"

# Output location for generate_control_csv_1 task and name of summary file
CONTROL_FILES_DIR = "Control_Files"
CONTROL_SUMMARY_FILE_NAME = "all.csv"

# Output location for files produced by simulation
SIM_FILES_DIR = "Simulation_Files"

# Output location for files after metrics added
CALC_METRICS_DIR = "Calc_Metrics"

# Final results directory
RESULTS_DIR = "Results"
RESULTS_FILE_NAME = 'results.csv'


