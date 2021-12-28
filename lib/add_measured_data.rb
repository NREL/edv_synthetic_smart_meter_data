require_relative 'constants'
require_relative '../lib/helper/measured_data_calculation'

if ARGV[0].nil? || !File.exist?(ARGV[0]) || ARGV[1].nil? || !Dir.exist?(ARGV[1])
  puts 'usage: bundle exec ruby csv_to_xmls /path/to/meta/with/csv /path/to/xmlFolder'
  puts '.csv files only'
  exit(1)
end

csv_file_path = ARGV[0]
xml_file_path = ARGV[1]

if !csv_file_path.nil? && !csv_file_path.empty?

  measure_data_calculation = MeasuredDataCalculation.new
  measure_data_calculation.initiate_measure_data_calculation(csv_file_path, xml_file_path)
end




