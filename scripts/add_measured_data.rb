
require_relative '../scripts/helper/measured_data_calculation'

if ARGV[0].nil? || !File.exist?(ARGV[0]) || ARGV[1].nil? || !Dir.exist?(ARGV[1])
  puts 'usage: bundle exec ruby csv_to_xmls /path/to/meta/with/csv /path/to/xmlFolder'
  puts '.csv files only'
  exit(1)
end

# output directory
outdir = "./#{NAME_OF_OUTPUT_DIR}/Bldg_Sync_Files_w_Measured_Data"
FileUtils.mkdir_p(outdir) unless File.exist?(outdir)

# csv_file_path = 'E:\Bricr\edv-experiment-1\spec\files\temp_open_utc.csv'
# xml_file_path = 'E:\Bricr\edv-experiment-1\Test_output\Bldg_Sync_Files'
csv_file_path = ARGV[0]
xml_file_path = ARGV[1]

if !csv_file_path.nil? && !csv_file_path.empty?

  measure_data_calculation = MeasuredDataCalculation.new
  measure_data_calculation.intiate_measure_data_calculation(csv_file_path, xml_file_path)
end




