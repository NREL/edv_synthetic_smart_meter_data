require 'rspec/core/rake_task'
require_relative 'scripts/constants'
RSpec::Core::RakeTask.new(:spec)

desc 'generate BDGP BuildingSync XMLs'
task :generate_bdgp_xmls do

  if ARGV[1]

    # ARGV[1] should be a path to a CSV file
    ruby "scripts/bdgp_to_buildingsync.rb #{ARGV[1]}"

  else
    # need path to csv file
    puts 'Error - No CSV file specified'
    puts 'Usage: bundle exec rake generate_bdgp_xmls path/to/csv/file'

  end

end

desc 'generate csv control file 1'
task :generate_control_csv_1 do

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
  else
    # need path to a directory with BldgSync files
    puts "Error - No directory with BuildingSync files specified"
    puts "Usage: bundle exec rake generate_csv_containing_all_bldgs path/to/bldgsync/dir (optional) standard_to_be_used csv/file/with/EPWs weather/file/source/dir"

  end
end

desc 'simulate a BDGP BuildingSync XML'
task :simulate_bdgp_xml do

  if ARGV[1] && ARGV[2] && ARGV[3] && ARGV[4]
    # ARGV[4] should be a path to DDY file
    ruby "scripts/simulate_bdgp_xml.rb #{ARGV[1]} #{ARGV[2]} #{ARGV[3]} #{ARGV[4]}"
  elsif ARGV[1] && ARGV[2] && ARGV[3]
    # ARGV[3] should be a path to EPW file
    ruby "scripts/simulate_bdgp_xml.rb #{ARGV[1]} #{ARGV[2]} #{ARGV[3]}"
  elsif ARGV[1] && ARGV[2]
    # ARGV[2] should be the standard_to_be_used
    ruby "scripts/simulate_bdgp_xml.rb #{ARGV[1]} #{ARGV[2]}"
  elsif ARGV[1]
    # ARGV[1] should be a path to a BDGP BuildingSync XML file
    ruby "scripts/simulate_bdgp_xml.rb #{ARGV[1]}"
  else
    # need path to csv file
    puts 'Error - No BDGP BuildingSync XML file specified'
    puts 'Usage: bundle exec rake simulate_bdgp_xml path/to/xml/file'
  end
end

desc 'simulate a batch of BDGP BuildingSync XML files'
task :simulate_batch_bdgp_xml do

  if ARGV[1] && ARGV[2]
    # ARGV[2] would be the folder with building sync files
    ruby "scripts/process_all_bldg_sync_files_in_csv.rb #{ARGV[1]} #{ARGV[2]}"
  elsif ARGV[1]
    # ARGV[1] should be a path to a BDGP BuildingSync XML file
    ruby "scripts/process_all_bldg_sync_files_in_csv.rb #{ARGV[1]}"

  else
    # need path to csv file
    puts 'Error - No CSV file specified that would contain the BldgSync files to be process in this batch'
    puts 'Usage: bundle exec rake process_all_bldg_sync_files_in_csv path/to/csv/file (optional) path/to/dir/with/bldgsyncfiles'

  end
end

desc 'export the synthetic data'
task :export_synthetic_data do

  if ARGV[1]

    # ARGV[1] should be a path to a BDGP BuildingSync XML file
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

desc 'Read the CSV file and update the BuildingSync files'
task :add_measured_data do

  if ARGV[1] && ARGV[2]

    # ARGV[1] should be a path to a CSV file
    ruby "scripts/add_measured_data.rb #{ARGV[1]} #{ARGV[2]}"

  else
    # need path to csv file
    puts 'Error - No CSV files specified'
    puts 'Usage: rake add_measured_data /path/to/meta/with/csv /path/to/buildingsync/folder/XML/files'

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

  edv_exp_1_files_dir = "../edv-experiment-1-files"
  if !File.exists?(edv_exp_1_files_dir)
    puts edv_exp_1_files_dir.to_s + " does not exist.  Make sure the edv-experiment-1-files directory is in the same parent directory as the edv-experiment-files directory"
    exit(1)
  end

  epw_csv_file_location = edv_exp_1_files_dir + "/bdgp_with_climatezones_epw_ddy.csv"
  weather_files_location = edv_exp_1_files_dir + "/weather"

  if !File.file?(epw_csv_file_location)
    puts epw_csv_file_location.to_s + " does not exist."
    exit(1)
  end

  if !File.exists?(weather_files_location)
    puts weather_files_location.to_s + " does not exist."
    exit(1)
  end

  temp_open_utc_file = "data/raw/temp_open_utc.csv"
  if !File.file?(temp_open_utc_file)
    puts temp_open_utc_file.to_s + " does not exist"
    exit(1)
  end

  output_dir = NAME_OF_OUTPUT_DIR
  bldg_sync_files = output_dir + "/Bldg_Sync_Files"
  bdgp_summary_file = bldg_sync_files + "/bdgp_summary.csv"
  bldg_sync_files_w_measured_data = output_dir + "/Bldg_Sync_Files_w_Measured_Data"
  control_files_dir = output_dir + "/Control_Files"
  all_csv_file = control_files_dir + "/all.csv"


  # Generate buildingsync xml files from epw_csv_file
  puts("")
  ruby "scripts/bdgp_to_buildingsync.rb " + epw_csv_file_location
  if File.exists?(bldg_sync_files)
    puts("")
    puts bldg_sync_files + " directory exists."
    if File.exists?(bdgp_summary_file)
      puts "Last modified time for bdgp_summary.csv: " + File.mtime(bdgp_summary_file).to_s
    else
      bdgp_summary_file.to_s + " does not exist.  Exiting program"
      exit(1)
    end
  else
    puts bldg_sync_files.to_s + " directory does not exist.  Exiting program."
    exit(1)
  end

  # Add measured data from BDGP to bldg_sync_files and save in second directory
  puts("")
  ruby "scripts/add_measured_data.rb " + temp_open_utc_file + " " + bldg_sync_files
  if File.exists?(bldg_sync_files_w_measured_data)
    puts("")
    puts bldg_sync_files_w_measured_data.to_s + " directory exists."
    if Dir.glob(bldg_sync_files_w_measured_data + "/*.xml").length > 1
      rec_file = Dir.glob(bldg_sync_files_w_measured_data + "/*.xml").max_by { |f| File.mtime(f) }
      puts "Most recently modified file: " + rec_file.to_s
      puts "File modified at: " + File.mtime(rec_file).to_s
    else
      puts "No files located in " + bldg_sync_files_w_measured_data.to_s + ". Exiting program"
      exit(1)
    end
  else
    puts bldg_sync_files_w_measured_data.to_s + " directory does not exist.  Exiting program"
    exit(1)
  end

  # Generate all.csv - used for running batch simulation of openstudio models down the line.
  puts("")
  ruby "scripts/generate_csv_containing_all_bldgs.rb " + bldg_sync_files_w_measured_data + " nil " + epw_csv_file_location + " " + weather_files_location
  if File.exists?(control_files_dir)
    puts("")
    puts control_files_dir.to_s + " directory exists."
    puts "Last modified time for all.csv: " + File.mtime(all_csv_file).to_s
  else
    puts control_files_dir.to_s + " directory does not exist.  Exiting program."
    exit(1)
  end
  puts("")

  puts("Finishing workflow_part_1")
end

desc 'Simulate batch and calculate metrics'
task :workflow_part_2 do
  output_dir = NAME_OF_OUTPUT_DIR
  all_csv_file = output_dir + "/Control_Files/all.csv"
  sim_results_dir = output_dir + "/Simulation_Files"

  if !File.exists?(all_csv_file)
    puts all_csv_file.to_s + " file does not exist.  Exiting program"
    exit(1)
  end

  puts("")
  ruby "scripts/process_all_bldg_sync_files_in_csv.rb " + all_csv_file
  puts("")
  if File.exists?(sim_results_dir)
    puts sim_results_dir.to_s + " directory exists."
    if Dir.glob(sim_results_dir + "/*.xml").length > 1
      rec_file = Dir.glob(bldg_sync_files_w_measured_data + "/*.xml").max_by { |f| File.mtime(f) }
      puts "Most recently modified file: " + rec_file.to_s
      puts "File modified at: " + File.mtime(rec_file).to_s
    else
      puts "No files located in " + sim_results_dir.to_s + ". Exiting program"
      exit(1)
    end
  else
    puts sim_results_dir.to_s + " directory does not exist.  Exiting program"
    exit(1)
  end

  puts("")
  ruby "scripts/calculate_metrics.rb " + sim_results_dir
  puts("")
  if Dir.glob(sim_results_dir + "/*.xml").length > 1
    rec_file = Dir.glob(bldg_sync_files_w_measured_data + "/*.xml").max_by { |f| File.mtime(f) }
    puts "Most recently modified file: " + rec_file.to_s
    puts "File modified at: " + File.mtime(rec_file).to_s
  else
    puts "No files located in " + sim_results_dir.to_s + ". Exiting program"
    exit(1)
  end

  puts("")
  puts "Finishing workflow_part_2"
end