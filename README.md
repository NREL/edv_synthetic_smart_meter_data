
# Energy Data Vault

These instructions are for installing and configuring environment to properly running EDV workflow.

## Installation

### Ruby 2.5.x

For OSX users, it is recommended that you install [rbenv](https://github.com/rbenv/rbenv) to manage different versions of Ruby. rbenv can be installed via [Homebrew](https://brew.sh/).

### Bundler 2.1.x

```
gem install bundler -v 2.1
```

### [OpenStudio](https://www.openstudio.net/downloads)

- Windows

Create a file ```C:\ruby-2.5.5-x64-mingw32\lib\ruby\site_ruby\openstudio.rb``` and point it to your OpenStudio installation by editing the contents.  E.g.:

```ruby
require 'C:\openstudio-3.0.0\Ruby\openstudio.rb'
```

Verify your OpenStudio and Ruby configuration:
```
ruby -e "require 'openstudio'" -e "puts OpenStudio::Model::Model.new"
```

- macOS

Add the RUBYLIB environment variable to your `bash_profile` (or similar) file. It should point to the Ruby folder within
the OpenStudio Application you just downloaded (replace 3.0.0 with the version you are using):
```
export RUBYLIB=/Applications/OpenStudio-3.0.0/Ruby
```


## Workflow Overview

![alt text](ScriptOverview.PNG)

### Configurations

Workflow can be configured in various ways per user desire. Configurations listed below are defined in ```scripts/constants.rb```:

- Data source: input data for workflow.
- Simulation type: baseline only scenarios or pre-defined energy efficiency measures.
- Input and output directories.
- Variability application type: variability in building operation to be implemented in the simulation.

### Input Data Source Standardization

Custom metadata and time-series data can be standardized for creating synthetic smart meter dataset. All processed data shall be stored in ```data/processed``` directory.

- Sample metadata [metadata_template](https://github.com/NREL/edv-experiment-1/blob/develop/data/raw/metadata_template.csv) and sample time-series data [timeseriesdata_template](https://github.com/NREL/edv-experiment-1/blob/develop/data/raw/timeseriesdata_template.csv) can be found in ```data/raw``` direcotry.

  - metadata used in the current workflow:
    - ```building_id```
    - ```xml_filename```
    - ```primary_building_type```
    - ```floor_area_sqft```
    - ```vintage```
    - ```climate_zone```
    - ```zipcode```
    - ```city```
    - ```us_state```
    - ```longitude```
    - ```latitude```
    - ```number_of_stories```
    - ```number_of_occupants```
    - ```fuel_type```
    - ```energystar_score```
    - ```measurement_start_date```
    - ```measurement_end_date```
    - ```weather_file_name_epw```
    - ```weather_file_name_ddy```

- Custom weather data can be stored in ```data/weather``` directory.



### Executing the Workflow:
#### To run rake task without warnings: export RUBYOPT=-W0 ####

Execute all rake tasks from root directory.

To run rake task without warnings, add following command to your ```bash_profile``` (or similar) file:
```
export RUBYOPT=-W0
```

#### Step 1 (optional): convert raw data to standard input data format. Example:

```
rake standardize_metadata_and_timeseriesdata
```

- Note that rake task ```standardize_metadata_and_timeseriesdata``` works exclusively for [Building Data Genome Project](https://github.com/buds-lab/building-data-genome-project-2). Users should create a custom rake task to convert raw input data to standard format.

- Skip if [BuildingSync](https://buildingsync.net/) files with sufficient building metadata imported direclty from [SEED](https://bricr.seed-platform.org/) are used as input data source.


#### Step 2: Generate BuildingSync XMLs

```
rake generate_xmls
```

- The generated XML files will be saved ```workflow_results/Bldg_Sync_Files``` direcotry specified in ```constant.rb```. These data are not to be committed.

- Skip if [BuildingSync](https://buildingsync.net/) files with sufficient building metadata imported direclty from [SEED](https://bricr.seed-platform.org/).



#### Step 3: Add measured time-series data to BuildingSync XMLs

```
rake add_measured_data
```

- Previously generated BuildingSync XMLs are now updated with time-series energy consumption data.

- Skip if [BuildingSync](https://buildingsync.net/) files with sufficient building metadata imported direclty from [SEED](https://bricr.seed-platform.org/).



#### Step 4: Generate simulation control file

- The following rake task will generate a csv file that contains a list of simulation scenarios specifying dedicated BuildingSync XML files and associated weather files. 
```
rake generate_control_csv
```

- The output control file contains the name of the BuildingSync file, the Standard to define buildings, and weather file names.

- The output control file is saved in ```Control_Files``` directory per ```constants.rb```.

- If BuildingSync XMLs imported from SEED are to be used, the location of the directory where these XMLs are stored should be used as an additional argument to rake task.

- Weather files (EPWs and DDYs) are required. As default, all weather files are saved in ```data/weather``` directory.



#### Step 5: Run building simulations (generate synthetic data) for all buildings

- This rake task translates BuildingSync XMLs into OSMs/OSWs for simulations:
```
rake simulate_batch_xml
```

- The generated simulation files as well as updated BuildingSync XMLs will be saved in the ```workflow_results/Simulation_Files``` directory.



#### Step 6: Calculate metrics with real and synthetic data

- This rake task calculates Actual EUI, Modeled EUI, CVRMSE, and NMBE from measured and simulated electricity data.
```
rake generate_metrics_result <Simulation_Files_Dir>
```

- Currently, only monthly data metric calculation is implmented.


#### Step 7: Generate synthetic time-series data

- This rake task combines before and after intervention time-series data and creates a new set of time-series data that indicates before and after intervention content (e.g., energy efficiency measure, non-routine event) based on the timing of the interventions. Intervention scenarios are defined in a separate csv file. 
```
rake export_synthetic_data path/to/configuration/csv/file
```

- See [format](https://github.com/NREL/edv-experiment-1/blob/develop/spec/files/generation_script.csv) of configuration csv file.


# TODO

- [ ] Update figures;
- [ ] To include capability for more granular timeseries data for step 5.
