# edv-experiment-1

## Installation

Clone the repo and run

``` bundle install ```

## Convert CSV Data to BuildingSync XML

Run the following command to generate BuildingSync XMLs from CSV data:

``` bundle exec rake generate_bdgp_xmls path/to/csv/file ```

The generated XML files will be put in the bdgp_output directory.

This script is designed to work with the metadata from the [Building Data Genome Project](https://github.com/buds-lab/the-building-data-genome-project/tree/master/data/raw).


*Note*: Do not commit generated BuildingSync XMLs to this repo.  Do not commit the CSV data to the repo either.