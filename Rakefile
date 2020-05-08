require 'rspec/core/rake_task'
require_relative 'scripts/constants'
RSpec::Core::RakeTask.new(:spec)

desc 'generate BuildingSync XMLs'
task :generate_xmls do

  default_metadata_file = "#{RAW_DATA_DIR}/#{DEFAULT_METADATA_FILE}"
  bdgp_cz_metadata_file = "../edv-experiment-1-files/BDGP/#{BDGP_CZ_METADATA_FILE}"
  if ARGV[1]

    # ARGV[1] should be a path to a CSV file
    ruby "scripts/meta_to_buildingsync.rb #{ARGV[1]}"

  elsif RUN_TYPE == 'default' && File.exist?(default_metadata_file)
    ruby "scripts/meta_to_buildingsync.rb #{default_metadata_file}"
  elsif RUN_TYPE == 'bdgp-cz' && File.exist?(bdgp_cz_metadata_file)
    ruby "scripts/meta_to_buildingsync.rb #{bdgp_cz_metadata_file}"
  else
    # need path to csv file
    puts "Error - No CSV file specified and default not found at: #{default_metadata_file}"
    puts 'Usage: bundle exec rake generate_xmls path/to/csv/file'
  end
end

desc 'Read the CSV file and update the BuildingSync files'
task :add_measured_data do

  default_path_to_csv = "#{RAW_DATA_DIR}/#{TIMESERIES_DATA_FILE}"
  default_path_to_xmls = "#{NAME_OF_OUTPUT_DIR}/#{GENERATE_DIR}"
  if ARGV[1] && ARGV[2]

    # ARGV[1] should be a path to a CSV file
    ruby "scripts/add_measured_data.rb #{ARGV[1]} #{ARGV[2]}"

  elsif (RUN_TYPE == 'default' || RUN_TYPE == 'bdgp-cz') && File.exist?(default_path_to_csv) && Dir.exist?(default_path_to_xmls)

    ruby "scripts/add_measured_data.rb #{default_path_to_csv} #{default_path_to_xmls}"

  else
    puts 'Error - No CSV files specified'
    puts 'Usage: rake add_measured_data /path/to/meta/with/csv /path/to/buildingsync/folder/XML/files'

  end
end

desc 'generate csv control file 1'
task :generate_control_csv_1 do

  default_path_to_add_measured = "#{NAME_OF_OUTPUT_DIR}/#{ADD_MEASURED_DIR}"
  bdgp_cz_metadata_file = "../edv-experiment-1-files/BDGP/#{BDGP_CZ_METADATA_FILE}"
  bdgp_cz_weather = "../edv-experiment-1-files/#{WEATHER_DIR}"

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
  elsif RUN_TYPE == 'default' && Dir.exist?(default_path_to_add_measured)
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{default_path_to_add_measured}"
  elsif RUN_TYPE == 'bdgp-cz' && Dir.exist?(default_path_to_add_measured) && File.exist?(bdgp_cz_metadata_file) && Dir.exist?(bdgp_cz_weather)
    ruby "scripts/generate_csv_containing_all_bldgs.rb #{default_path_to_add_measured} nil #{bdgp_cz_metadata_file} #{bdgp_cz_weather}"
  else
    # need path to a directory with BldgSync files
    puts "Error - No directory with BuildingSync files specified"
    puts "Usage: bundle exec rake generate_csv_containing_all_bldgs path/to/bldgsync/dir (optional) standard_to_be_used csv/file/with/EPWs weather/file/source/dir"

  end
end

desc 'Test single file simulation'
task :single_file_run do
  output_dir = NAME_OF_OUTPUT_DIR
  all_csv_file = output_dir + "/#{CONTROL_FILES_DIR}/#{CONTROL_SUMMARY_FILE_NAME}"
  ruby "scripts/process_single_bldg_sync_file_in_csv.rb " + all_csv_file
end

desc 'Test single file simulation with occupancy variability'
task :single_file_run_occ_var do
  output_dir = NAME_OF_OUTPUT_DIR
  all_csv_file = output_dir + "/#{CONTROL_FILES_DIR}/#{CONTROL_SUMMARY_FILE_NAME}"
  ruby "scripts/process_single_bldg_sync_file_in_csv.rb " + all_csv_file
end

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

desc 'export the synthetic data'
task :export_synthetic_data do

  if ARGV[1]

    # ARGV[1] should be a path to a BuildingSync XML file
    ruby "scripts/export_synthetic_data.rb #{ARGV[1]}"

  else
    # need path to csv file
    puts 'Error - No CSV file specified that would contain information about the export process'
    puts 'Usage: bundle exec rake export_synthetic_data path/to/csv/file'

  end
end


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

desc 'Read the directory, iterate over BldgSync files and calcuate the metrics'
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

desc 'Run steps through generating all.csv'
task :workflow_part_1 do
  Rake::Task["generate_xmls"].execute
  Rake::Task["add_measured_data"].execute
  Rake::Task["generate_control_csv_1"].execute
end

desc 'Simulate batch and calculate metrics'
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