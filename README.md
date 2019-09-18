# edv-experiment-1

## Installation

Install Ruby and OpenStudio as [described here](https://github.com/NREL/openstudio-extension-gem/blob/develop/README.md#installation).

Clone this repo and run

``` bundle install ```

## Output path

All output will go into a path this is defined with the constant NAME_OF_OUTPUT_DIR in the constants.rb file, 
below the edv-experiment-1 main folder. 

## Script overview

The following figure contains an overview of the scripts and input as well as output files/paths:

![alt text](ScriptOverview.PNG)

## Convert CSV Data to BuildingSync XML

Run the following command to generate BuildingSync XMLs from CSV data:

``` bundle exec rake generate_bdgp_xmls path/to/csv/file ```

The generated XML files will be put in the NAME_OF_OUTPUT_DIR/Bldg_Sync_Files directory.

This script is designed to work with the metadata `meta_open.csv` from the [Building Data Genome Project](https://github.com/buds-lab/the-building-data-genome-project/tree/master/data/raw).

*Note*: Do not commit generated BuildingSync XMLs to this repo.  Do not commit the CSV data to the repo either.\

## Simulate BuildingSync XML file (one)
Run the following command to translate one BuildingSync XML to OSM and simulate:

``` bundle exec rake simulate_bdgp_xml path/to/xml/file ```

## Simulate BuildingSync XML file (batch of files)

Run the following command to translate BuildingSync XMLs to OSMs/OSWs and run all related simulations:

``` bundle exec rake simulate_batch_bdgp_xml path/to/csv/file ```

In this case the CSV file contains the name of the BuildingSync file, the Standard to use and the weather file in comma separated format.

The generated simulation files will be put in the NAME_OF_OUTPUT_DIR/Simulation_Files directory.

#### Generate the csv file

The following script will generate a csv file with all BuildingSync files found in the NAME_OF_OUTPUT_DIR/Bldg_Sync_Files directory. 

``` bundle exec rake generate_control_csv_1 path/to/bldg_snyc_files (optional) standard_to_be_used csv/file/with/EPWs path/to/weather/files```

The first argument is required and should be the path to the BuildingSync files
The other three arguments are optional. The 2nd one can set the standard (ASHRAE 90.1 or T24), 
the 3rd and forth can also use actual weather files based on the related csv file and a path to the weather files

## Export data using the synthetic exporter

The following script will export data according to the instructions in the csv file. 

``` bundle exec rake export_synthetic_data path/to/csv/file```

The csv file contains: the following rows:
- realization_name
- basic_scenario_dir
- building_id
- default_scenario
- start_date
- end_date
- scenario_name_1
- active_after_1
- scenario_name_2
- active_after_2
- ...

## Missing

TODO: usage of geocode and loopup_climate scripts



