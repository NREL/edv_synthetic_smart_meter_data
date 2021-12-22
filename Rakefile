# require 'rspec/core/rake_task'
# RSpec::Core::RakeTask.new(:spec)
require_relative 'scripts/constants'

#############################################################################################

desc 'convert raw data to standardized data format'
task :format_data, [:data_option] do |_, args|
  case args.data_option.downcase
  when 'bdgp'
    puts 'standardizing the format of BDGP2 data'
    ruby 'scripts/format_data_bdgp.rb'
  when 'sf'
    puts 'standardizing the format of SF data'
    ruby 'scripts/format_data_sf.rb'
  when 'sf_monthly'
    puts 'standardizing the format of SF data'
    ruby 'scripts/format_data_sf.rb'
  else
    puts 'Usage: rake format_data[data_option] path/to/metadata path/to/timeseriesdata'
  end
end

#############################################################################################

desc 'generate BuildingSync XMLs'
task :generate_xmls do
  default_metadata_file = "#{RAW_DATA_DIR}/#{DEFAULT_METADATA_FILE}"
  processed_metadata_file = "#{PROCESSED_DATA_DIR}/#{PROCESSED_METADATA_FILE}"

  if ARGV[1]

    # ARGV[1] should be a path to a metadata CSV file
    ruby "scripts/meta_to_buildingsync.rb #{ARGV[1]}"

  elsif RUN_TYPE == 'default' && File.exist?(default_metadata_file)
    ruby "scripts/meta_to_buildingsync.rb #{default_metadata_file}"
  elsif RUN_TYPE == 'processed' && File.exist?(processed_metadata_file)
    ruby "scripts/meta_to_buildingsync.rb #{processed_metadata_file}"
  else
    # need path to csv file
    puts 'Error - No CSV or default file specified.'
    puts 'Usage: rake generate_xmls path/to/metadata/csv/file'
  end
end

#############################################################################################

desc 'read the CSV file and update the BuildingSync files'
task :add_measured_data do
  default_timeseries_file = "#{RAW_DATA_DIR}/#{DEFAULT_TIMESERIESDATA_FILE}"
  processed_timeseries_file = "#{PROCESSED_DATA_DIR}/#{PROCESSED_TIMESERIESDATA_FILE}"
  default_path_to_xmls = "#{WORKFLOW_OUTPUT_DIR}/#{GENERATE_DIR}"

  if ARGV[1] && ARGV[2]

    # ARGV[1] should be a path to a CSV file
    ruby "scripts/add_measured_data.rb #{ARGV[1]} #{ARGV[2]}"

  elsif RUN_TYPE == 'default' && File.exist?(default_timeseries_file) && Dir.exist?(default_path_to_xmls)
    ruby "scripts/add_measured_data.rb #{default_timeseries_file} #{default_path_to_xmls}"
  elsif RUN_TYPE == 'processed' && File.exist?(processed_timeseries_file) && Dir.exist?(default_path_to_xmls)
    ruby "scripts/add_measured_data.rb #{processed_timeseries_file} #{default_path_to_xmls}"
  else
    puts 'Error - No CSV files specified'
    puts 'Usage: rake add_measured_data path/to/timeseriesdata/csv/file /path/to/buildingsync/XML/files/folder'
  end
end

#############################################################################################

desc 'generate csv control file'
task :generate_control_csv do
  default_metadata_file = "#{RAW_DATA_DIR}/#{DEFAULT_METADATA_FILE}"
  processed_metadata_file = "#{PROCESSED_DATA_DIR}/#{PROCESSED_METADATA_FILE}"
  weather_dir = "#{DEFAULT_WEATHERDATA_DIR}"

  if ARGV[1] && ARGV[2] && ARGV[3] && ARGV[4]
    # ARGV[4] should be a path to a directory with weather files
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{ARGV[1]} #{ARGV[2]} #{ARGV[3]} #{ARGV[4]}"

  elsif ARGV[1] && ARGV[2] && ARGV[3]
    # ARGV[3] should be a path to csv_file_with_EPWs
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{ARGV[1]} #{ARGV[2]} #{ARGV[3]}"

  elsif ARGV[1] && ARGV[2]
    # ARGV[2] should be the standard_to_be_used
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{ARGV[1]} #{ARGV[2]}"

  elsif ARGV[1]
    # ARGV[1] should be a path to a directory with BldgSync files (root_dir)
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{ARGV[1]} "

  elsif RUN_TYPE == 'default' && Dir.exist?("#{WORKFLOW_OUTPUT_DIR}/#{MEASURED_DATA_DIR}") && File.exist?(default_metadata_file) && Dir.exist?(weather_dir)
    puts "reading BSync files from #{"#{WORKFLOW_OUTPUT_DIR}/#{MEASURED_DATA_DIR}"}"
    puts "reading metadata from #{default_metadata_file}"
    puts "reading weather files from #{weather_dir}"
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{"#{WORKFLOW_OUTPUT_DIR}/#{MEASURED_DATA_DIR}"} nil #{default_metadata_file} #{weather_dir}"

  elsif RUN_TYPE == 'default' && Dir.exist?("#{WORKFLOW_OUTPUT_DIR}/#{GENERATE_DIR}") && File.exist?(default_metadata_file) && Dir.exist?(weather_dir)
    puts "reading BSync files from #{"#{WORKFLOW_OUTPUT_DIR}/#{GENERATE_DIR}"}"
    puts "reading metadata from #{default_metadata_file}"
    puts "reading weather files from #{weather_dir}"
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{"#{WORKFLOW_OUTPUT_DIR}/#{GENERATE_DIR}"} nil #{default_metadata_file} #{weather_dir}"

  elsif RUN_TYPE == 'processed' && Dir.exist?("#{WORKFLOW_OUTPUT_DIR}/#{MEASURED_DATA_DIR}") && File.exist?(processed_metadata_file) && Dir.exist?(weather_dir)
    puts "reading BSync files from #{"#{WORKFLOW_OUTPUT_DIR}/#{MEASURED_DATA_DIR}"}"
    puts "reading metadata from #{processed_metadata_file}"
    puts "reading weather files from #{weather_dir}"
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{default_path_to_add_measured_data} nil #{processed_metadata_file} #{weather_dir}"

  elsif RUN_TYPE == 'processed' && Dir.exist?("#{WORKFLOW_OUTPUT_DIR}/#{GENERATE_DIR}") && File.exist?(processed_metadata_file) && Dir.exist?(weather_dir)
    puts "reading BSync files from #{"#{WORKFLOW_OUTPUT_DIR}/#{GENERATE_DIR}"}"
    puts "reading metadata from #{processed_metadata_file}"
    puts "reading weather files from #{weather_dir}"
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{"#{WORKFLOW_OUTPUT_DIR}/#{GENERATE_DIR}"} nil #{processed_metadata_file} #{weather_dir}"

  else
    puts 'Error - No BuildingSync files specified'
    puts 'Usage: rake generate_csv_containing_all_bldgs <bsync_files_Dir> (optional) <standard_to_be_used> <metadata_file> <weather_file>'
  end
end

#############################################################################################

desc 'simulate a single BuildingSync XML files'
task :single_file_run do
  output_dir = WORKFLOW_OUTPUT_DIR
  all_csv_file = output_dir + "/#{CONTROL_FILES_DIR}/#{CONTROL_SUMMARY_FILE_NAME}"
  ruby "scripts/process_single_bldg_sync_file_in_csv.rb #{all_csv_file}"
end

#############################################################################################

desc 'simulate a batch of BuildingSync XML files'
task :simulate_batch_xml do
  output_dir = WORKFLOW_OUTPUT_DIR
  all_csv_file = output_dir + "/#{CONTROL_FILES_DIR}/#{CONTROL_SUMMARY_FILE_NAME}"
  if ARGV[1] && ARGV[2]
    # ARGV[2] would be the folder with building sync files
    ruby "scripts/process_all_bldg_sync_files_in_csv.rb #{ARGV[1]} #{ARGV[2]}"
  elsif ARGV[1]
    # ARGV[1] should be a path to a BuildingSync XML file
    ruby "scripts/process_all_bldg_sync_files_in_csv.rb #{ARGV[1]}"
  elsif File.exist?(all_csv_file)
    ruby "scripts/process_all_bldg_sync_files_in_csv.rb #{all_csv_file}"
  else
    # need path to csv file
    puts 'Error - No CSV file specified that would contain the BldgSync files to be process in this batch'
    puts 'Usage: rake process_all_bldg_sync_files_in_csv path/to/csv/file (optional) path/to/dir/with/bldgsyncfiles'
  end
end

#############################################################################################

desc 'building calibration'
task :calibration do
  ruby 'scripts/calibration.rb'
end

#############################################################################################

desc 'create synthetic data that are stictched between different scenarios'
task :export_synthetic_data do
  if ARGV[1]
    # ARGV[1] should be a path to a BuildingSync XML file
    ruby "scripts/export_synthetic_data.rb #{ARGV[1]}"
  else
    # need path to csv file
    puts 'Error - No CSV file specified that would contain information about the export process'
    puts 'Usage: rake export_synthetic_data path/to/scenario/configuration/csv/file'
  end
end

#############################################################################################

desc 'append lat/lng/zipcode information to CSV'
task :geocode_meta_csv do
  if ARGV[1] && ARGV[2]
    # ARGV[1] should be a path to a CSV file
    ruby "scripts/map_latlng.rb #{ARGV[1]} #{ARGV[2]}"
  else
    # need path to csv file
    puts 'Error - No CSV files specified'
    puts 'Usage: rake geocode_meta_csv /path/to/meta/csv /path/to/latlng/csv'
  end
end

#############################################################################################

desc 'lookup and append climate_zone information to CSV'
task :lookup_climate_zone_csv do
  if ARGV[1] && ARGV[2]
    # ARGV[1] should be a path to a CSV file
    ruby "scripts/map_zipcode.rb #{ARGV[1]} #{ARGV[2]}"
  else
    # need path to csv file
    puts 'Error - No CSV files specified'
    puts 'Usage: rake lookup_climate_zone_csv /path/to/meta/with/zipcodes/csv /path/to/climate/lookup/csv'
  end
end

#############################################################################################

desc 'read the directory, iterate over BldgSync files and calcuate the metrics'
task :generate_metrics_result do
  if ARGV[1]
    # ARGV[1] should be a path to a CSV file
    ruby "scripts/calculate_metrics.rb #{ARGV[1]}"
    ruby 'scripts/sum_metrics.rb'
  else
    # need path to csv file
    puts 'Error - No directory with BldgSync files specified'
    puts 'Usage: rake calculate_metrics /path/to/dir/with/simulated/data'
  end
end

#############################################################################################

desc 'run steps through generating all.csv'
task :workflow_part1 do
  Rake::Task['generate_xmls'].execute
  Rake::Task['add_measured_data'].execute
  Rake::Task['generate_control_csv'].execute
end

#############################################################################################

desc 'simulate batch and calculate metrics'
task :workflow_part2 do
  output_dir = WORKFLOW_OUTPUT_DIR
  all_csv_file = output_dir + "/#{CONTROL_FILES_DIR}/#{CONTROL_SUMMARY_FILE_NAME}"
  sim_results_dir = output_dir + "/#{SIM_FILES_DIR}"
  bldg_sync_files_w_metrics = output_dir + "/#{CALC_METRICS_DIR}"
  results_dir = output_dir + "/#{RESULTS_DIR}"

  unless File.exist?(all_csv_file)
    puts "Rake: #{all_csv_file} file does not exist. Exiting program"
    exit(1)
  end

  ruby "scripts/process_all_bldg_sync_files_in_csv.rb #{all_csv_file}"

  if File.exist?(sim_results_dir)
    if Dir.glob("#{sim_results_dir}/*.xml").length >= 1
      rec_file = Dir.glob("#{sim_results_dir}/*.xml").max_by { |f| File.mtime(f) }
      puts "Rake: Most recently modified file: #{rec_file}"
      puts "Rake: File modified at: #{File.mtime(rec_file)}"
    else
      puts "Rake: No XML files found in #{sim_results_dir}. Exiting program"
      exit(1)
    end
  else
    puts "Rake: #{sim_results_dir} directory does not exist.  Exiting program"
    exit(1)
  end

  ruby "scripts/calculate_metrics.rb #{sim_results_dir}"

  if Dir.glob("#{bldg_sync_files_w_metrics}/*.xml").length >= 1
    rec_file = Dir.glob("#{bldg_sync_files_w_metrics}/*.xml").max_by { |f| File.mtime(f) }
    puts "Rake: Most recently modified file: #{rec_file}"
    puts "Rake: File modified at: #{File.mtime(rec_file)}"
  else
    puts "Rake: No files found in #{sim_results_dir}. Exiting program"
    exit(1)
  end
 
  ruby 'scripts/sum_metrics.rb'

  unless File.exist?(results_dir)
    puts "Rake: #{sim_results_dir} file does not exist. Exiting program"
    exit(1)
  end

  puts 'Rake: Finishing workflow_part_2'
end

#############################################################################################

desc 'Apply typical operation hours detection to hourly measured data'
task :typical_operation_hours do
  exec('python', 'scripts/algorithm_typical_operation_hours.py', default_path_to_add_measured_data)
end

#############################################################################################

desc 'eemeter takes il-electricity-cdd-hdd-daily object'
task :eemeter_object, [:file] do |_, args|
  if args[:file]
    ruby "scripts/bsync_to_eemeter.rb #{args[:file]}"
  else
    ruby 'scripts/bsync_to_eemeter.rb'
  end
end

# argv should be path to a directory of al buildingsync files to feed all hourly data from .xml to NMEC
desc 'eemeter takes il-electricity-cdd-hdd-daily.csv file'
task :eemeter_file do
  if ARGV[1]
    ruby "scripts/bsync_to_eemeter.rb #{ARGV[1]}"
  else
    ruby 'scripts/bsync_to_eemeter.rb'
  end
end

# BuildingSync eemeter
desc 'eemeter takes bsync file'
task :bsync_eemeter do
  ruby 'scripts/bsync_to_eemeter.rb'
end
