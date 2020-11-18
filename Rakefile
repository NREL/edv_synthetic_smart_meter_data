require 'rspec/core/rake_task'
require_relative 'scripts/constants'
RSpec::Core::RakeTask.new(:spec)

default_path_to_add_measured = "#{NAME_OF_OUTPUT_DIR}/#{ADD_MEASURED_DIR}"
#############################################################################################
desc 'convert raw data to standardized data format'
task :standardize_metadata_and_timeseriesdata do


  #TODO JK: need to change file location to bdgp repo once bdgp2 data intake mod is implemented.
  raw_metadata_file = "../building-data-genome-project-2/data/metadata/metadata.csv" #metadata file containing private info
  raw_timeseries_file = "../building-data-genome-project-2/data/meters/raw/electricity.csv" #timeseries file in the same location for easy access
  #raw_metadata_file = "../the-building-data-genome-project/data/raw/meta_open.csv" #metadata in public version
  #raw_timeseries_file = "../the-building-data-genome-project/data/raw/temp_open_utc.csv"
  
  if ARGV[1] && ARGV[2]

    # ARGV[1] should be a path to a CSV file
    ruby "scripts/rawdata_to_standardized_input_BDGP.rb #{ARGV[1]} #{ARGV[2]}"

  elsif File.exist?(raw_metadata_file) && File.exist?(raw_timeseries_file)
    ruby "scripts/rawdata_to_standardized_input_BDGP.rb #{raw_metadata_file} #{raw_timeseries_file}"
  else
    # need path to csv file
    puts "Error - No CSV file specified and default not found at: #{raw_metadata_file}"
    puts "Error - No CSV file specified and default not found at: #{raw_timeseries_file}"
    puts 'Usage: bundle exec rake standardize_metadata_and_timeseriesdata path/to/metadata/csv/file path/to/timeseriesdata/csv/file'
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
    puts "Error - No CSV file specified and default not found at either #{default_metadata_file} or #{processed_metadata_file}"
    puts 'Usage: bundle exec rake generate_xmls path/to/metadata/csv/file'
  end
end
#############################################################################################
desc 'read the CSV file and update the BuildingSync files'
task :add_measured_data do

  default_timeseries_file = "#{RAW_DATA_DIR}/#{DEFAULT_TIMESERIESDATA_FILE}"
  processed_timeseries_file = "#{PROCESSED_DATA_DIR}/#{PROCESSED_TIMESERIESDATA_FILE}"
  default_path_to_xmls = "#{NAME_OF_OUTPUT_DIR}/#{GENERATE_DIR}"

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
  default_weather = "#{DEFAULT_WEATHERDATA_DIR}"
  processed_weather = "../edv-experiment-1-files/weather" #private weather data

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
  elsif RUN_TYPE == 'default' && Dir.exist?(default_path_to_add_measured) && File.exist?(default_metadata_file) && Dir.exist?(default_weather)
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{default_path_to_add_measured} nil #{default_metadata_file} #{default_weather}"
  elsif RUN_TYPE == 'processed' && Dir.exist?(default_path_to_add_measured) && File.exist?(processed_metadata_file) && Dir.exist?(processed_weather)
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{default_path_to_add_measured} nil #{processed_metadata_file} #{processed_weather}"
  else
    # need path to a directory with BldgSync files
    puts "Error - No directory with BuildingSync files specified"
    puts "Usage: bundle exec rake generate_csv_containing_all_bldgs /path/to/buildingsync/XML/files/folder (optional) standard_to_be_used path/to/metadata/csv/file weather/file/source/dir"

  end
end
#############################################################################################
desc 'simulate a single BuildingSync XML files'
task :single_file_run do
  output_dir = NAME_OF_OUTPUT_DIR
  all_csv_file = output_dir + "/#{CONTROL_FILES_DIR}/#{CONTROL_SUMMARY_FILE_NAME}"
  ruby "scripts/process_single_bldg_sync_file_in_csv.rb " + all_csv_file
end
#############################################################################################
desc 'simulate a batch of BuildingSync XML files'
task :simulate_batch_xml do

  output_dir = NAME_OF_OUTPUT_DIR
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
    puts 'Usage: bundle exec rake process_all_bldg_sync_files_in_csv path/to/csv/file (optional) path/to/dir/with/bldgsyncfiles'

  end
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
    puts 'Usage: bundle exec rake export_synthetic_data path/to/scenario/configuration/csv/file'

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
task :calculate_metrics do

  if ARGV[1]

    # ARGV[1] should be a path to a CSV file
    ruby "scripts/calculate_metrics.rb #{ARGV[1]}"

  else
    # need path to csv file
    puts 'Error - No directory with BldgSync files specified'
    puts 'Usage: rake calculate_metrics /path/to/dir/with/simulated/data'

  end
end
#############################################################################################
desc 'run steps through generating all.csv'
task :workflow_part_1 do
  Rake::Task["generate_xmls"].execute
  Rake::Task["add_measured_data"].execute
  Rake::Task["generate_control_csv"].execute
end
#############################################################################################
desc 'simulate batch and calculate metrics'
task :workflow_part_2 do
  output_dir = NAME_OF_OUTPUT_DIR
  all_csv_file = output_dir + "/#{CONTROL_FILES_DIR}/#{CONTROL_SUMMARY_FILE_NAME}"
  sim_results_dir = output_dir + "/#{SIM_FILES_DIR}"
  bldg_sync_files_w_metrics = output_dir + "/#{CALC_METRICS_DIR}"
  results_dir = output_dir + "/#{RESULTS_DIR}"
  results_file = results_dir + "/#{RESULTS_FILE_NAME}"

  if !File.exists?(all_csv_file)
    puts "Rake: " + all_csv_file.to_s + " file does not exist.  Exiting program"
    exit(1)
  end

  puts("")
  ruby "scripts/process_all_bldg_sync_files_in_csv.rb " + all_csv_file
  puts("")
  if File.exists?(sim_results_dir)
    puts "Rake: " + sim_results_dir.to_s + " directory exists."
    if Dir.glob(sim_results_dir + "/*.xml").length >= 1
      rec_file = Dir.glob(sim_results_dir + "/*.xml").max_by { |f| File.mtime(f) }
      puts "Rake: Most recently modified file: " + rec_file.to_s
      puts "Rake: File modified at: " + File.mtime(rec_file).to_s
    else
      puts "Rake: No XML files located in " + sim_results_dir.to_s + ". Exiting program"
      exit(1)
    end
  else
    puts "Rake: " + sim_results_dir.to_s + " directory does not exist.  Exiting program"
    exit(1)
  end

  puts("")
  ruby "scripts/calculate_metrics.rb " + sim_results_dir
  puts("")
  if Dir.glob(bldg_sync_files_w_metrics + "/*.xml").length >= 1
    rec_file = Dir.glob(bldg_sync_files_w_metrics + "/*.xml").max_by { |f| File.mtime(f) }
    puts "Rake: Most recently modified file: " + rec_file.to_s
    puts "Rake: File modified at: " + File.mtime(rec_file).to_s
  else
    puts "Rake: No files located in " + sim_results_dir.to_s + ". Exiting program"
    exit(1)
  end

  puts("")
  ruby "scripts/sum_metrics.rb"
  puts("")
  if File.exists?(results_dir)
    puts "Rake: " + results_dir.to_s + " directory exists"
    if File.exists?(results_file)
      puts "Rake: " + results_file.to_s + " file exists."
    else
      puts "Rake: " + sim_results_dir.to_s + " file does not exist. Exiting program"
      exit(1)
    end
  end

  puts("")
  puts "Rake: Finishing workflow_part_2"
end

#############################################################################################
desc 'Apply typical operation hours detection to hourly measured data'
task :typical_operation_hours do
  exec("python", "scripts/algorithm_typical_operation_hours.py", default_path_to_add_measured)
end
