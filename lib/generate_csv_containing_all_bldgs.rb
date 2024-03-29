require 'fileutils'
require 'csv'
require_relative 'constants'

if !ARGV[0].nil? && Dir.exist?(ARGV[0])
  root_dir = ARGV[0] 
else
  root_dir = "./#{WORKFLOW_OUTPUT_DIR}/#{GENERATE_DIR}"
end
puts "<<<<<<------DEBUGGING------>>>>>> searching BSync XML files from #{root_dir}"

standard_to_be_used = 'ASHRAE90.1'
if !ARGV[1].nil? && (ARGV[1] == 'CaliforniaTitle24' || ARGV[1] == 'ASHRAE90.1')
  standard_to_be_used = ARGV[1]
end
puts "<<<<<<------DEBUGGING------>>>>>> building standard to be used: #{standard_to_be_used}"

epw_file = 'temporary.epw'
ddy_file = 'temporary.ddy'
temp_dir = File.expand_path('../', File.dirname(__FILE__))
epw_arr = []
if !ARGV[2].nil? && File.exist?(ARGV[2])

  puts "<<<<<<------DEBUGGING------>>>>>> metadata reading from: #{ARGV[2]}"

  options = {headers:true, header_converters: :symbol}
  CSV.foreach(ARGV[2], options) do |row|

    the_hash = {}
    the_hash[:building_id] = row[:building_id]

    if !row[:weather_file_name_epw]
      the_hash[:weather_file_name_epw] = epw_file
    else
      the_hash[:weather_file_name_epw] = row[:weather_file_name_epw]
    end

    if !row[:weather_file_name_ddy]
      the_hash[:weather_file_name_ddy] = ddy_file
    else
      the_hash[:weather_file_name_ddy] = row[:weather_file_name_ddy]
    end

    epw_arr << the_hash
  end
end

weather_file_source_dir = ""
if !ARGV[3].nil?  && Dir.exist?(ARGV[3])
  weather_file_source_dir = ARGV[3]
end

puts "<<<<<<------DEBUGGING------>>>>>> weather_file_source_dir = #{ARGV[3]}"

csv_file_path = File.expand_path("../#{WORKFLOW_OUTPUT_DIR}/Control_Files/all.csv", File.dirname(__FILE__))
FileUtils.mkdir_p File.dirname(csv_file_path)

csv = File.open(csv_file_path, 'w')

Dir.glob("#{root_dir}/*.xml").each do |xml_file|
  matches = epw_arr.select { |row| row[:building_id] === File.basename(xml_file, ".xml") }
  
  begin
    if matches.size > 0
      if (!matches[0][:weather_file_name_epw].nil?) || (!matches[0][:weather_file_name_ddy].nil?)
        if matches[0][:weather_file_name_epw] == 'temporary.epw' || matches[0][:weather_file_name_ddy] == 'temporary.ddy'
          weather_file_source_dir = DEFAULT_WEATHERDATA_DIR
        end
        epw_file = File.expand_path(matches[0][:weather_file_name_epw], weather_file_source_dir)
        ddy_file = File.expand_path(matches[0][:weather_file_name_ddy], weather_file_source_dir)
      end
    end
  rescue => e
    puts "ERROR - could not add epw and ddy info to #{File.basename(xml_file, ".xml")}"
  end

  csv.puts("#{File.basename(xml_file)},#{standard_to_be_used},#{epw_file},#{ddy_file}")
  csv.flush
end

csv.close
puts "*************************"
puts "* Control CSV generated *"
puts "*************************"
