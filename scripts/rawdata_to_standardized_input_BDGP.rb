# convert raw format of Building Data Genome Project data to standardized metadata and timeseries data

require 'csv'
require 'fileutils'
require_relative 'constants'

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

metadata_file = File.open(outdir + '/metadata.csv', 'w')
metadata_file.puts 'building_id,xml_filename,primary_building_type,floor_area_sqft,vintage,climate_zone,zipcode,city,us_state,longitude,latitude,number_of_stories,number_of_occupants,fuel_type_heating,energystar_score,measurement_start_date,measurement_end_date,weather_file_name_epw,weather_file_name_ddy'

options = {headers: true,
           header_converters: :symbol}

CSV.foreach(ARGV[0], options) do |feature|
  
  building_id = feature[:uid]
  primary_building_type = feature[:primaryspaceusage]
  floor_area_sqft = feature[:sqft]
  vintage = feature[:yearbuilt]
  climate_zone = feature[:climate_zone]
  weather_file_name_epw = feature[:epw]
  weather_file_name_ddy = feature[:ddy]
  zipcode = feature[:zipcode]
  city = feature[:city]
  us_state = feature[:state]
  longitude = feature[:lng]
  latitude = feature[:lat]
  number_of_stories = feature[:numberoffloors]
  number_of_occupants = feature[:occupants]
  fuel_type_heating = feature[:heatingtype]
  energystar_score = feature[:energystarscore]
  measurement_start_date = feature[:datastart]
  measurement_end_date = feature[:dataend]

  metadata_file.puts "#{building_id},#{building_id}.xml,#{primary_building_type},#{floor_area_sqft},#{vintage},#{climate_zone},#{zipcode},#{city},#{us_state},#{longitude},#{latitude},#{number_of_stories},#{number_of_occupants},#{fuel_type_heating},#{energystar_score},#{measurement_start_date},#{measurement_end_date},#{weather_file_name_epw},#{weather_file_name_ddy}"

end

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
