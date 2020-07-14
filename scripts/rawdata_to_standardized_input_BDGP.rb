# convert raw format of Building Data Genome Project data to standardized metadata and timeseries data

require 'csv'
require 'fileutils'
require_relative 'constants'
require_relative 'helper/standardize_input'

if ARGV[0].nil? || !File.exist?(ARGV[0])
  puts 'Error - No metadata CSV file specified'
  exit(1)

end

if ARGV[1].nil? || !File.exist?(ARGV[1])
  puts 'Error - No timeseries CSV file specified'
  exit(1)

end

# output directory
outdir = "./data/processed"
FileUtils.mkdir_p(outdir) unless File.exist?(outdir)

#######################################################################
# metadata data conversion from raw labels to standardized labels
#######################################################################

std_label = ['building_id','xml_filename','primary_building_type','floor_area_sqft','vintage','climate_zone','zipcode','city','us_state','longitude','latitude','number_of_stories','number_of_occupants','fuel_type_heating','energystar_score','measurement_start_date','measurement_end_date','weather_file_name_epw','weather_file_name_ddy']

StandardizedInput.new.copy_columns(ARGV[0], std_label, outdir)

#######################################################################
# timeseries data conversion from raw labels to standardized labels
#######################################################################

data_original = CSV.read(ARGV[1])
header = CSV.open(ARGV[1], &:readline)
#header[header.index("timestamp")] = "timestamp"

CSV.open(outdir + '/timeseriesdata.csv', "w", :headers => true) do |csv|
  csv << header
  data_original.each_with_index {|row,i| next if i == 0; csv << row } #HOW TO SKIP FIRST ROW
end
