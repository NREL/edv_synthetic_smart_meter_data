WORKFLOW_OUTPUT_DIR = "workflow_results"
INPUT_DIR = "inputs"

# EDITABLE
# Options include: ['default', 'processed']
RUN_TYPE = "processed"

# Options: true, false
BASELINE_ONLY = true
OCC_VAR = false
NON_ROUTINE_VAR = {
    :DR_GTA_os => false,
    :DR_Lighting_os => false,
    :DR_MELs_os => false,
    :DR_Precool_Preheat_os => false,
    :Fault_AirHandlingUnitFanMotorDegradation_ep => false,
    :Fault_BiasedEconomizerSensorMixedT_ep => false,
    :Fault_BiasedEconomizerSensorOutdoorRH_ep => false,
    :Fault_BiasedEconomizerSensorOutdoorT_ep => false,
    :Fault_BiasedEconomizerSensorReturnRH_ep => false,
    :Fault_BiasedEconomizerSensorReturnT_ep => false,
    :Fault_DuctFouling_os => false,
    :Fault_EconomizerOpeningStuck_os => false,
    :Fault_ExcessiveInfiltration_os => false,
    :Fault_HVACSetbackErrorDelayedOnset_os => false,
    :Fault_HVACSetbackErrorEarlyTermination_os => false,
    :Fault_HVACSetbackErrorNoOvernightSetback_os => false,
    :Fault_thermostat_offset_ep => false,
    :Retrofit_equipment_os => false,
    :Retrofit_lighting_os => false,
    :Retrofit_exterior_wall_ep => false,
    :Retrofit_roof_ep => false,
}

# DO NOT EDIT
# Directory within edv-experiment-1 where raw or processed data exists
RAW_DATA_DIR = "data/raw"
PROCESSED_DATA_DIR = "data/processed"
DEFAULT_WEATHERDATA_DIR = "data/weather/temporary"

# Input file names for generate_xmls, assumed location depends on RUN_TYPE
DEFAULT_METADATA_FILE = "metadata_template.csv"
PROCESSED_METADATA_FILE = "metadata.csv"
DEFAULT_TIMESERIESDATA_FILE = "timeseriesdata_template.csv"
PROCESSED_TIMESERIESDATA_FILE = "timeseriesdata.csv"

# Output location for generate_xmls task and name of summary file
GENERATE_DIR = "Bldg_Sync_Files"

# Output location for add_measured_data task
ADD_MEASURED_DIR = "Add_Measured_Data_Files"

# Output location for generate_control_csv_1 task and name of summary file
CONTROL_FILES_DIR = "Control_Files"
CONTROL_SUMMARY_FILE_NAME = "all.csv"

# Output location for files produced by simulation
SIM_FILES_DIR = "Simulation_Files"

# Calibration output directory
CALIBRATION_OUTPUT_DIR = "Calibration_Files"

# Output location for files after metrics added
CALC_METRICS_DIR = "Calc_Metrics"

# Final results directory
RESULTS_DIR = "Results"
RESULTS_FILE_NAME = 'results.csv'

# SF DATA
# Change this arg to a cmd line arg
SF_MONTHLY = true
BDGP = false