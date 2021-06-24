# convert raw format of Building Data Genome Project data to standardized metadata and timeseries data

require 'csv'
require 'fileutils'
require_relative 'constants'
require 'geocoder'

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

def map_location_with_latlng(file, outdir, options = {headers: true, header_converters: :symbol})
  updated_features = []
  lat_lng_arr = []

  CSV.foreach(file, options) do |row|
    lat_lng_arr << {:building_id => row[:building_id], :lat => row[:lat], :lng => row[:lng]}
  end

  puts "###############################################"
  CSV.foreach(file, options).with_index do |feature, i|
    puts "Verifying latitude and longitude in location #{i.next} out of #{lat_lng_arr.size} locations"

    # geocoder
    res = Geocoder.search("#{feature[:lat]}, #{feature[:lng]}")
    if (feature[:lat].to_s.empty?)||(feature[:lng].to_s.empty?)
      feature[:zipcode] = ""
      puts "zipcode: n/a"
      feature[:city] = ""
      puts "city: n/a"
      feature[:state] = ""
      puts "state: n/a"
    else
      feature[:zipcode] = res.first.postal_code
      puts "zipcode: #{res.first.postal_code}"
      feature[:city] = res.first.city
      puts "city: #{res.first.city}"
      feature[:state] = res.first.state
      puts "state: #{res.first.state}"
    end
    puts "###############################################"
    updated_features << feature
  end
  
  updated_features
end

def copy_columns(file, std_labels, outdir, updated_features, options = {headers: true, header_converters: :symbol})
  metadata_file = File.open(outdir + '/metadata.csv', 'w+')

  puts "Adding standard labels (header names) into metadata.csv file"
  metadata_file.puts std_labels
    
  puts "Adding values of standard labels into metadata.csv file"
  updated_features.each do |row|
    building_id = row[:building_id]
    primary_building_type = row[:primaryspaceusage]
    floor_area_sqft = row[:sqft]
    vintage = row[:yearbuilt]
    climate_zone = row[:climate_zone]
    weather_file_name_epw = row[:epw]
    weather_file_name_ddy = row[:ddy]
    zipcode = row[:zipcode]
    city = row[:city]
    us_state = row[:state]
    longitude = row[:lng]
    latitude = row[:lat]
    number_of_stories = row[:numberoffloors]
    number_of_occupants = row[:occupants]
    fuel_type = row[:heatingtype]
    energystar_score = row[:energystarscore]
    measurement_start_date = row[:datastart]
    measurement_end_date = row[:dataend]

    metadata_file.puts "#{building_id},#{building_id}.xml,#{primary_building_type},#{floor_area_sqft},#{vintage},#{climate_zone},#{zipcode},#{city},#{us_state},#{longitude},#{latitude},#{number_of_stories},#{number_of_occupants},#{fuel_type},#{energystar_score},#{measurement_start_date},#{measurement_end_date},#{weather_file_name_epw},#{weather_file_name_ddy}"

  end
  puts "###############################################"
  
end

updated_features = map_location_with_latlng(ARGV[0], outdir)

std_labels = 'building_id,xml_filename,primary_building_type,floor_area_sqft,vintage,climate_zone,zipcode,city,us_state,longitude,latitude,number_of_stories,number_of_occupants,fuel_type,energystar_score,measurement_start_date,measurement_end_date,weather_file_name_epw,weather_file_name_ddy'
copy_columns(ARGV[0], std_labels, outdir, updated_features)

data_original = CSV.read(ARGV[1])
header = CSV.open(ARGV[1], &:readline)

puts "Copying timeseries data into timeseriesdata.csv file"
CSV.open(outdir + '/timeseriesdata.csv', "w", :headers => true) do |csv|
  csv << header
  data_original.each_with_index {|row,i| next if i == 0; csv << row }
end
