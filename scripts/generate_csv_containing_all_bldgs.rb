require 'fileutils'

root_dir = File.expand_path( '../', File.dirname(__FILE__))
puts "root_dir:#{root_dir}"

if !ARGV[0].nil?  && Dir.exist?(ARGV[0])
  root_dir = ARGV[0]
end

standard_to_be_used = 'ASHRAE90.1'
if !ARGV[1].nil? && (ARGV[1] == 'CaliforniaTitle24' || ARGV[1] == 'ASHRAE90.1')
  standard_to_be_used = ARGV[1]
end
puts "standard_to_be_used:#{standard_to_be_used}"

epw_file = 'temporary.epw'
if !ARGV[2].nil? && File.exist?(ARGV[2])
  epw_file = ARGV[2]
end
puts "epw_file:#{epw_file}"

csv_file_path = File.expand_path('../spec/output/csv_files/all.csv', File.dirname(__FILE__))
FileUtils.mkdir_p File.dirname(csv_file_path)
xml_files = []
csv = File.open(csv_file_path, 'w')
Dir.glob("#{root_dir}/bdgp_output/*.xml").each do |xml_file|
  puts "xml_file: #{xml_file} "
  puts "xml_file: #{File.basename(xml_file)}"
  puts "standard: #{standard_to_be_used}"
  puts " epw: #{epw_file}"
  csv.puts("#{File.basename(xml_file)},#{standard_to_be_used},#{epw_file}")
  csv.flush
end
csv.close

puts 'bye'

