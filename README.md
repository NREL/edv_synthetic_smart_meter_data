# Installation

In order to execute the workflow properly, certain environments listed below need to be installed.

- Install Ruby and OpenStudio

  - Current working versions,
    - [Ruby 2.2.4](https://rubyinstaller.org/downloads/archives/)
    - Bundler 1.17.1 (use ```gem install bundler -v 1.17```)
    - [OpenStudio 2.9.0](https://github.com/NREL/OpenStudio/releases/tag/v2.9.0) 
  - Follow the [instruction](https://github.com/NREL/openstudio-standards/blob/master/docs/DeveloperInformation.md) for current working versions.

- Clone this repository and run commands below in the highest directory of the repository.
```
bundle install
```
```
bundle update
``` 

- TODO,
  - update installation instructions when transitioning to OpenStudio 3.0 and Ruby 2.5.5



# Script Overview

The following figure contains an overview of the workflow.


![alt text](ScriptOverview.PNG)

- TODO,
  - update figure
  
  

# Configurations Before Running the Entire Workflow

There are different ways to control and configure the workflow based on included capabilities. ```constants.rb``` file under ```scripts``` folder includes configurations listed below.

- selection of the data source: which data is going to be used as an input to the workflow?
- selection of simulation type: are simulations going to consider baseline scenarios only? or will be considering pre-defined energy efficiency measures?
- configuration of directories: where do inputs read from? and where do outputs being saved?
- configuration of variability application: what kind of variability in building operation is going to be implemented in the simulation?



# Standardized Input Data Source

User can use their own data for creating synthetic smart meter data set by standardizing the format of metadata and timeseries data as described below.

- Sample template files for [metadata](https://github.com/NREL/edv-experiment-1/blob/develop/data/raw/metadata_template.csv) and [timeseries data](https://github.com/NREL/edv-experiment-1/blob/develop/data/raw/timeseriesdata_template.csv) that represent the standard input format are included under ```data/raw``` folder

  - metadata information that can be used in the current workflow are,
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
    - ```fuel_type_heating```
    - ```energystar_score```
    - ```measurement_start_date```
    - ```measurement_end_date```
    - ```weather_file_name_epw```
    - ```weather_file_name_ddy```
    
  - format of timeseries file can be referred to the template file ```timeseriesdata_template.csv``` and the column headers representing the building id should match with ```building_id``` in the metadata file.

- Custom weather data can be stored in ```data/weather``` folder 



# Executing the Workflow: Step-by-step for Every Task

All rake commands are executed in the highest directory of this repository.



### Step 0 (optional): Convert raw data format from Building Data Genome Project to standardized input format

- Run the following command to convert raw data to standardized format:
```
bundle exec rake standardize_metadata_and_timeseriesdata
```

- This step is only necessary when [Building Data Genome Project](https://github.com/buds-lab/building-data-genome-project-2) data is being used.

- This step can be skipped if importing [BuildingSync](https://buildingsync.net/) XML files from [SEED](https://bricr.seed-platform.org/) and if the XML files are already including sufficient metadata information of buildings.



### Step 1: Generate BuildingSync XMLs from standardized building metadata

- Run the following command to generate BuildingSync XMLs from CSV data:
```
bundle exec rake generate_xmls
```

- The generated XML files will be saved in a location specified in the configuration ```constant.rb``` file.

- This step can be skipped if importing BuildingSync XML files from SEED and if the XML files are already including sufficient metadata information of buildings.

- Note: make sure not to commit data that includes private information to this repo.



### Step 2: Add measured data into BuildingSync XMLs from standardized timeseries data  

- Run the following command to add measured energy consumptions to the BuildingSync XMLs generated in step 1:
```
bundle exec rake add_measured_data
```

- The updated XML files will be saved based on the configuration in ```constant.rb``` file.

- Currently, monthly interval data are only calculated and stored back to xmls.

- This step can be skipped if importing BuildingSync XML files from SEED and if the XML files are already including sufficient metadata information of buildings.

- TODO,
  - add capability for adding granular (e.g., daily, hourly) timeseries data to XML files. 



### Step 3: Generate the simulation control file

- The following script will generate a csv file that creates a list of simulation scenarios specifying BuildingSync XML files and associated weather files. 
```
bundle exec rake generate_control_csv
```

- The output control file contains the name of the BuildingSync file, the Standard to define buildings, and weather file names.

- The output control file will be saved based on the configuration in ```constant.rb``` file.

- If user has imported/downloaded BuildingSync XMLs from SEED, then the location to the folder that contains BuildingSync XMLs should be specified as an argument to the rake command.

- Users need to acquire weather files (EPWs and DDYs) separately and weather files could be saved under ```data/weather``` folder as a default location.



### Step 4: Run building simulations (generate synthetic data) for all buildings

- Run the following command to translate BuildingSync XMLs to OSMs/OSWs and run simulations:
```
bundle exec rake simulate_batch_xml
```

- The generated simulation files as well as updated BuildingSync XMLs will be saved in the NAME_OF_OUTPUT_DIR/Simulation_Files directory.



### Step 5: Calculate metrics based on information from both real and synthetic data

- Run the following command to calculate Actual EUI, Modeled EUI, CVRMSE, and NMBE from measured and simulated electricity data.
```
bundle exec rake calculate_metrics path/to/simulation/results/created/from/previous/step
```

- Currently, metric calculations based on monthly data are only possible.

- TODO,
  - include capability for granular (e.g., daily, hourly) timeseries data.



### Step 6: Generate stitched timeseries synthetic data

- The following script will create a single timeseries data that includes both pre- and post- interventions (e.g., energy efficiency measure, non-routine event) by stitching them together based on the definitions of when interventions happened. The scenarios for defining interventions are configured in another csv file. 
```
bundle exec rake export_synthetic_data path/and/name/of/configuration/csv/file
```

- The format of the configuration file is shown [here](https://github.com/NREL/edv-experiment-1/blob/develop/spec/files/generation_script.csv)




