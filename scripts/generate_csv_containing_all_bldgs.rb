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
epw_arr = []
if !ARGV[2].nil? && File.exist?(ARGV[2])
  csv_file_with_EPWs = ARGV[2]

  options = {headers:true, header_converters: :symbol}

  CSV.foreach(csv_file_with_EPWs, options) do |row|
    the_hash = {}
    the_hash[:uid] = row[:uid]
    the_hash[:epw] = row[:epw]
    epw_arr << the_hash
  end
  puts "custom epw_files found in :#{csv_file_with_EPWs}"
end

weather_file_source_dir = ""
if !ARGV[3].nil?  && Dir.exist?(ARGV[3])
  weather_file_source_dir = ARGV[3]
end

csv_file_path = File.expand_path("../#{NAME_OF_OUTPUT_DIR}/Control_Files/all.csv", File.dirname(__FILE__))
FileUtils.mkdir_p File.dirname(csv_file_path)
puts "csv_file_path: #{csv_file_path}"

csv = File.open(csv_file_path, 'w')
puts "Looking for #{"#{root_dir}/*.xml"} "
puts "found #{Dir.glob("#{root_dir}/*.xml").count} xml files in this directory. "
Dir.glob("#{root_dir}/*.xml").each do |xml_file|
  puts "xml_file: #{xml_file} "
  puts "xml_file: #{File.basename(xml_file, ".xml")}"
  puts "standard: #{standard_to_be_used}"
  matches = epw_arr.select {|row| row[:uid] === File.basename(xml_file, ".xml") }
  if matches.size > 0
    epw_file = File.expand_path(matches[0][:epw], weather_file_source_dir)
  end
  puts " epw: #{epw_file}"
  csv.puts("#{File.basename(xml_file)},#{standard_to_be_used},#{epw_file}")
  csv.flush
end
csv.close

puts "ARGV[0]:#{ARGV[0]} ARGV[1]:#{ARGV[1]} ARGV[2]:#{ARGV[2]} ARGV[3]:#{ARGV[3]}"

puts 'bye'

