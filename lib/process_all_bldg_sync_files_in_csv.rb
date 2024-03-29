# Run a BuildingSync XML file to generate synthetic smart meter data

require 'bundler/setup'
require 'openstudio/extension'
require 'openstudio/model_articulation'
require 'buildingsync'
require 'buildingsync/translator'
require_relative 'constants'
require_relative 'helper/simulate_bdgp_xml_path'

start = Time.now
puts "Simulation script started at #{start}"

OpenStudio::Extension::Extension::DO_SIMULATIONS = true
OpenStudio::Extension::Extension::NUM_PARALLEL = 1
BUILDINGS_PARALLEL = 20
BuildingSync::Extension::SIMULATE_BASELINE_ONLY = BASELINE_ONLY

if ARGV[0].nil?
  puts 'usage: bundle exec ruby process_all_bldg_sync_files_in_csv.rb path/to/csv/file'
  puts "must provide a .csv file"
  exit(1)
end

bldg_sync_file_dir = "../#{WORKFLOW_OUTPUT_DIR}/#{MEASURED_DATA_DIR}"
if !ARGV[1].nil?
  bldg_sync_file_dir = File.expand_path(ARGV[1])
  puts "<<<<<<------DEBUGGING------>>>>>> BSync XML files reading from: #{bldg_sync_file_dir}"
elsif File.exist?(bldg_sync_file_dir)
  puts "<<<<<<------DEBUGGING------>>>>>> BSync XML files reading from: #{bldg_sync_file_dir}"
else
  bldg_sync_file_dir = "../#{WORKFLOW_OUTPUT_DIR}/#{GENERATE_DIR}"
  puts "<<<<<<------DEBUGGING------>>>>>> BSync XML files reading from: #{bldg_sync_file_dir}"
end


csv_file_path = ARGV[0]
root_dir = File.join(File.dirname(__FILE__), '..')
out_path = File.join(root_dir, "/spec/output/")

if File.exist?(out_path)
  FileUtils.mkdir_p(out_path)
end

log_file_path = csv_file_path + '.log'

csv_table = CSV.read(csv_file_path)
log = File.open(log_file_path, 'w')

Parallel.each(csv_table, in_threads:BUILDINGS_PARALLEL) do |xml_file, standard, epw_file, ddy_file|
  puts "<<<<<<------DEBUGGING------>>>>>> processing xml_file: #{xml_file} - standard: #{standard} - epw_file: #{epw_file}"

  xml_file_path = File.expand_path("#{bldg_sync_file_dir}/#{xml_file}/", File.dirname(__FILE__))
  out_path = File.expand_path("#{bldg_sync_file_dir}/#{File.basename(xml_file, File.extname(xml_file))}/", File.dirname(__FILE__))

  puts "<<<<<<------DEBUGGING------>>>>>> xml_file_path: #{xml_file_path}" 
  puts "<<<<<<------DEBUGGING------>>>>>> out_path: #{out_path}" 

  epw_file_path = ''
  if File.exist?(epw_file)
    epw_file_path = epw_file
  else
    epw_file_path = File.expand_path("../scripts/#{epw_file}/", File.dirname(__FILE__))
  end

  puts "<<<<<<------DEBUGGING------>>>>>> epw file path: #{epw_file_path}" 
  
  ddy_file_path = ''
  if !ddy_file.nil?
    ddy_file_path = ddy_file
  else
    ddy_file = 'temporary.ddy'
    ddy_file_path = File.expand_path("../scripts/#{ddy_file}/", File.dirname(__FILE__))
  end

  puts "<<<<<<------DEBUGGING------>>>>>> ddy file path: #{epw_file_path}" 

  result = simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path, ddy_file_path, BASELINE_ONLY, OCC_VAR, NON_ROUTINE_VAR)

  #puts "...completed: #{result} and osm file exist: #{File.exist?("#{out_path}/in.osm")}"
  puts "<<<<<<------DEBUGGING------>>>>>> #{result} and osm file exist: #{File.exist?("#{out_path}/in.osm")}"

  output_dirs = []
  Dir.glob("#{out_path}/**/") { |output_dir| output_dirs << output_dir }
  output_dirs.each do |output_dir|
    if !output_dir.include? "/SR"
      if output_dir != out_path
        idf_file = File.join(output_dir, "/in.idf")
        sql_file = File.join(output_dir, "/results.json")
        if File.exist?(idf_file) && !File.exist?(sql_file)
          puts "...ERROR: #{sql_file} does not exist, simulation was unsuccessful}"
          log.flush
        end
      end
    end
  end
end
log.close

finish = Time.now
puts "<<<<<<------DEBUGGING------>>>>>> Simulation script completed at #{finish}"
diff = finish - start
puts "<<<<<<------DEBUGGING------>>>>>> Simulation script completed in #{diff} seconds, #{(diff.to_f/60).round(2)} minutes, #{(diff.to_f/3600).round(2)} hours, #{(diff.to_f/3600/24).round(2)} days"
