# Run a BuildingSync XML file to generate synthetic smart meter data

require 'openstudio/extension'
require 'openstudio/model_articulation/os_lib_model_generation_bricr'
require 'buildingsync'
require 'buildingsync/translator'
require 'openstudio/occupant_variability'
require_relative 'constants'

OpenStudio::Extension::Extension::DO_SIMULATIONS = true
OpenStudio::Extension::Extension::NUM_PARALLEL = 1
BUILDINGS_PARALLEL = 4
BuildingSync::Extension::SIMULATE_BASELINE_ONLY = true

if ARGV[0].nil?
  puts 'usage: bundle exec ruby process_all_bldg_sync_files_in_csv.rb path/to/csv/file'
  puts "must provide a .csv file"
  exit(1)
end

bldg_sync_file_dir = "../#{NAME_OF_OUTPUT_DIR}/Bldg_Sync_Files_w_Measured_Data"
if !ARGV[1].nil?
  bldg_sync_file_dir = ARGV[1]
end

start = Time.now
puts "Simulation script started at #{start}"

def simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path, ddy_file_path)
  out_path = File.expand_path("../#{NAME_OF_OUTPUT_DIR}/Simulation_Files/#{File.basename(xml_file_path, File.extname(xml_file_path))}/", File.dirname(__FILE__))
  out_xml = File.expand_path("../#{NAME_OF_OUTPUT_DIR}/Simulation_Files/#{File.basename(xml_file_path)}", File.dirname(__FILE__))
  root_dir = File.expand_path('..', File.dirname(__FILE__))

  begin
    translator = BuildingSync::Translator.new(xml_file_path, out_path, epw_file_path, standard, false)
    translator.add_measure_path("#{root_dir}/lib/measures")
    translator.insert_reporting_measure('hourly_consumption_by_fuel_to_csv', 0)
    translator.write_osm(ddy_file_path)
    translator.write_osws

    osws = Dir.glob("#{out_path}/**/in.osw")
    if BuildingSync::Extension::SIMULATE_BASELINE_ONLY
      osws = Dir.glob("#{out_path}/Baseline/in.osw")
    end

    puts "SIMULATE_BASELINE_ONLY: #{BuildingSync::Extension::SIMULATE_BASELINE_ONLY}"
    puts "osws: #{osws}"
    runner = OpenStudio::Extension::Runner.new(root_dir)
    runner.run_osws(osws, num_parallel=OpenStudio::Extension::Extension::NUM_PARALLEL)

    translator.gather_results(out_path)
    translator.save_xml(out_xml)
  rescue StandardError => e
    puts "Error occurred while processing #{xml_file_path} with message: #{e.message}"
  end
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

#csv_table.each do |xml_file, standard, epw_file, ddy_file|
  log.puts("processing xml_file: #{xml_file} - standard: #{standard} - epw_file: #{epw_file}")

  xml_file_path = File.expand_path("#{bldg_sync_file_dir}/#{xml_file}/", File.dirname(__FILE__))
  out_path = File.expand_path("../#{NAME_OF_OUTPUT_DIR}/Simulation_Files/#{File.basename(xml_file, File.extname(xml_file))}/", File.dirname(__FILE__))
  epw_file_path = ''
  if File.exist?(epw_file)
    epw_file_path = epw_file
  else
    epw_file_path = File.expand_path("../scripts/#{epw_file}/", File.dirname(__FILE__))
  end

  ddy_file_path = ''
  if File.exist?(ddy_file)
    ddy_file_path = ddy_file
  else
    ddy_file_path = File.expand_path("../scripts/#{ddy_file}/", File.dirname(__FILE__))
  end

  result = simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path, ddy_file_path)

  puts "...completed: #{result} and osm file exist: #{File.exist?("#{out_path}/in.osm")}"
  log.puts("...completed: #{result} and osm file exist: #{File.exist?("#{out_path}/in.osm")}")

  output_dirs = []
  Dir.glob("#{out_path}/**/") { |output_dir| output_dirs << output_dir }
  output_dirs.each do |output_dir|
    if !output_dir.include? "/SR"
      if output_dir != out_path
        idf_file = File.join(output_dir, "/in.idf")
        sql_file = File.join(output_dir, "/results.json")
        if File.exist?(idf_file) && !File.exist?(sql_file)
          log.puts("...ERROR: #{sql_file} does not exist, simulation was unsuccessful}")
          log.flush
        end
      end
    end
  end
end
log.close

finish = Time.now
puts "Simulation script completed at #{finish}"
diff = finish - start
puts "Simulation script completed in #{diff} seconds"
puts "Simulation script completed in #{diff.to_f/60} minutes"
puts "Simulation script completed in #{diff.to_f/3600} hours"
puts "Simulation script completed in #{diff.to_f/3600/24} days"