require 'fileutils'
require 'csv'
require_relative 'constants'

root_dir = File.expand_path('../', File.dirname(__FILE__))

root_dir = ARGV[0] if !ARGV[0].nil? && Dir.exist?(ARGV[0])

standard_to_be_used = 'ASHRAE90.1'
if !ARGV[1].nil? && (ARGV[1] == 'CaliforniaTitle24' || ARGV[1] == 'ASHRAE90.1')
  standard_to_be_used = ARGV[1]
end
puts "standard_to_be_used:#{standard_to_be_used}"

epw_file = 'temporary.epw'
ddy_file = 'temporary.ddy'
epw_arr = []
if !ARGV[2].nil? && File.exist?(ARGV[2])
  csv_file_with_EPWs = ARGV[2]

  options = {headers:true, header_converters: :symbol}

  CSV.foreach(csv_file_with_EPWs, options) do |row|
    the_hash = {}
    the_hash[:building_id] = row[:building_id]
    the_hash[:weather_file_name_epw] = row[:weather_file_name_epw]
    the_hash[:weather_file_name_ddy] = row[:weather_file_name_ddy]
    epw_arr << the_hash
  end
  puts "custom epw_files found in :#{csv_file_with_EPWs}"
end

weather_file_source_dir = ""
if !ARGV[3].nil?  && Dir.exist?(ARGV[3])
  weather_file_source_dir = ARGV[3]
end

csv_file_path = "#{NAME_OF_OUTPUT_DIR}/Control_Files/all.csv"
FileUtils.mkdir_p File.dirname(csv_file_path)
puts "csv_file_path: #{csv_file_path}"

csv = File.open(csv_file_path, 'w')
puts "Looking for #{"#{root_dir}/*.xml"} "
puts "found #{Dir.glob("#{root_dir}/*.xml").count} xml files in this directory. "
Dir.glob("#{root_dir}/*.xml").each do |xml_file|
  matches = epw_arr.select {|row| row[:building_id] === File.basename(xml_file, ".xml") }
  if matches.size > 0
    epw_file = File.expand_path(matches[0][:weather_file_name_epw], weather_file_source_dir)
    ddy_file = File.expand_path(matches[0][:weather_file_name_ddy], weather_file_source_dir)
  end
  # puts " epw: #{epw_file} ddy: #{ddy_file}"
  csv.puts("#{File.basename(xml_file)},#{standard_to_be_used},#{epw_file},#{ddy_file}")
  csv.flush
end
csv.close


