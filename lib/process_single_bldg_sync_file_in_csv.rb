require 'csv'
require_relative 'constants'
require_relative 'helper/simulate_bdgp_xml_path'

if ARGV[0].nil?
  puts 'usage: bundle exec ruby process_single_bldg_sync_files_in_csv.rb path/to/csv/file'
  puts "must provide a .csv file"
  exit(1)
end

start = Time.now
puts "Simulation script started at #{start}"

bldg_sync_file_dir = "../#{WORKFLOW_OUTPUT_DIR}/#{MEASURED_DATA_DIR}"
if !ARGV[1].nil?
  bldg_sync_file_dir = File.expand_path(ARGV[1])
end

# Read in csv file and extract first line from table
csv_file_path = ARGV[0]
csv_table = CSV.read(csv_file_path)
single_building = csv_table[0]

# Extract parameters from first line for simulation
xml_file = single_building[0]
standard = single_building[1]
epw_file = single_building[2]
ddy_file = single_building[3]

xml_file_path = File.expand_path("#{bldg_sync_file_dir}/#{xml_file}/", File.dirname(__FILE__))
out_path = File.expand_path("#{bldg_sync_file_dir}/#{File.basename(xml_file, File.extname(xml_file))}/", File.dirname(__FILE__))

epw_file_path = ''
if File.exist?(epw_file)
  epw_file_path = epw_file
else
  epw_file_path = File.expand_path("../data/weather/#{epw_file}/", File.dirname(__FILE__))
end

ddy_file_path = ''
if !ddy_file.nil?
  ddy_file_path = ddy_file
else
  ddy_file = 'temporary.ddy'
  ddy_file_path = File.expand_path("../data/weather/#{ddy_file}/", File.dirname(__FILE__))
end

# Run
result = simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path, ddy_file_path, BASELINE_ONLY, OCC_VAR, NON_ROUTINE_VAR)

output_dirs = []
Dir.glob("#{out_path}/**/") { |output_dir| output_dirs << output_dir }
output_dirs.each do |output_dir|
  if !output_dir.include? "/SR"
    if output_dir != out_path
      idf_file = File.join(output_dir, "/in.idf")
      sql_file = File.join(output_dir, "/results.json")
      if File.exist?(idf_file) && !File.exist?(sql_file)
        puts("...ERROR: #{sql_file} does not exist, simulation was unsuccessful}")
      end
    end
  end
end

finish = Time.now
puts "Simulation script completed at #{finish}"
diff = finish - start
puts "Simulation script completed in #{diff} seconds, #{(diff.to_f/60).round(2)} minutes, #{(diff.to_f/3600).round(2)} hours, #{(diff.to_f/3600/24).round(2)} days"
