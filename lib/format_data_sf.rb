# convert raw format of Building Data Genome Project data to standardized metadata and timeseries data

require 'csv'
require 'fileutils'
require_relative 'constants'

# sf monthly
sf_monthly_energy_file = File.join(__dir__, '../', 'data', 'raw', 'monthlyenergy_bricr_filtered2.csv')

# output directory
outdir = "./data/processed"
FileUtils.mkdir_p(outdir) unless File.exist?(outdir)

def map_location_with_latlng(file, outdir, options = {headers: true, header_converters: :symbol})
  updated_features = []
  lat_lng_arr = []

  CSV.foreach(file, options) do |row|
    lat_lng_arr << {:building_id => row[:id]}
  end

  CSV.foreach(file, options).with_index do |feature, i|

    feature[:zipcode] = ""
    feature[:city] = "San Francisco"
    feature[:state] = "California"
    feature[:lat] = 37.7749
    feature[:lng] = 122.4194

    updated_features << feature

  end

  updated_features
  
end

def copy_columns(file, std_labels, outdir, updated_features, options = {headers: true, header_converters: :symbol})
  metadata_file = File.open(outdir + '/metadata.csv', 'w+')
  metadata_file.puts std_labels

  updated_features.each do |row|
    building_id = row[:id]
    primary_building_type = row[:bricr_occupancy_classification]
    floor_area_sqft = row[:bricr_building_footprint_floor_area_ft2]
    vintage = row[:bricr_completed_construction_status_date]
    climate_zone = row[:climate_zone]
    zipcode = row[:zipcode]
    city = row[:city]
    us_state = row[:state]
    longitude = row[:lng]
    latitude = row[:lat]
    number_of_stories = row[:bricr_number_of_floors]
    number_of_occupants = row[:occupants]
    fuel_type = 'electricity/gas'
    measurement_start_date = '1/2018'
    measurement_end_date = '12/2018'
    weather_file_name_epw = 'USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw'
    weather_file_name_ddy = 'USA_CA_San.Francisco.Intl.AP.724940_TMY3.ddy'

    metadata_file.puts "#{building_id},#{building_id}.xml,#{primary_building_type},#{floor_area_sqft},#{vintage},#{climate_zone},#{zipcode},#{city},#{us_state},#{longitude},#{latitude},#{number_of_stories},#{number_of_occupants},#{fuel_type},#{measurement_start_date},#{measurement_end_date},#{weather_file_name_epw},#{weather_file_name_ddy}"

  end
  
end

updated_features = map_location_with_latlng(sf_monthly_energy_file, outdir)

std_labels = 'building_id,xml_filename,primary_building_type,floor_area_sqft,vintage,climate_zone,zipcode,city,us_state,longitude,latitude,number_of_stories,number_of_occupants,fuel_type,measurement_start_date,measurement_end_date,weather_file_name_epw,weather_file_name_ddy'
copy_columns(sf_monthly_energy_file, std_labels, outdir, updated_features)

data_original = CSV.read(sf_monthly_energy_file)
header = CSV.open(sf_monthly_energy_file, &:readline)

header_id = ['timestamp', 'fuel_type']
CSV.open(outdir + '/timeseriesdata.csv', "w", :headers => true) do |csv|
  data_original.each_with_index do |row, i|
    next if i == 0
    header_id << row[header.find_index('id')]
  end
  csv << header_id

  table = CSV.table(sf_monthly_energy_file)
  table.headers.select {|header| header[/seed_2018_([1-9]|1[0-2])_/]}.each do |header|
    header_info = header.to_s.split('_')
    csv << table[:"#{header}"].insert(0, "#{header_info[2]}/#{header_info[1]}").insert(1, "#{header_info[3]}")
  end
  puts "#######################################################################"
  puts "Successfully formatted metadata and timeseries data for SF monthly data."
  puts "#######################################################################"
end
