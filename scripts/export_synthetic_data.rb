# export synthetic smart meter data

require 'openstudio/extension'
require 'openstudio/model_articulation/os_lib_model_generation_bricr'
require 'buildingsync'
require 'buildingsync/translator'
require 'openstudio/occupant_variability'
require_relative 'constants'

if ARGV[0].nil?
  puts 'usage: bundle exec ruby export_synthetic_data.rb path/to/csv/file'
  puts "must provide at least a .csv file"
  exit(1)
end

if !File.exist?(ARGV[0])
  puts 'usage: bundle exec ruby export_synthetic_data.rb path/to/csv/file'
  puts "CSV file does not exist: #{ARGV[0]}"
  exit(1)
end

ROW_NO_NAME = 0
ROW_NO_BASE_DIR = 1
ROW_NO_BUILDING_ID = 2
ROW_NO_DEFAULT_SCENARIO = 3
ROW_NO_START_DATE = 4
ROW_NO_END_DATE = 5
ROW_NO_SCENARIO_COUNT = 6

csv_file_path = ARGV[0]

# read the column headers so we now how many files we need to process
column_headers = CSV.read(csv_file_path, headers: true).headers
# read in the CSV file into an array
parsed = CSV.read(csv_file_path)

# iterate over the columns with files
for i in 1..column_headers.count-1
  name = parsed[ROW_NO_NAME][i]
  base_dir = parsed[ROW_NO_BASE_DIR][i]
  building_id = parsed[ROW_NO_BUILDING_ID][i]
  default_scenario = parsed[ROW_NO_DEFAULT_SCENARIO][i]
  start_date = parsed[ROW_NO_START_DATE][i]
  end_date = parsed[ROW_NO_END_DATE][i]
  scenario_count = ROW_NO_SCENARIO_COUNT

  # create an array of active scenarios
  active_scenarios = Array.new
  active_scenarios << [default_scenario, start_date]
  puts "------------------------------------------------------"
  puts "- Verify simulation scenarios for case #{i}"
  puts "------------------------------------------------------"
  puts "parsed[scenario_count].nil? #{parsed[scenario_count].nil?}"
  if !parsed[scenario_count].nil?
    until parsed[scenario_count][i].nil?
      puts "scenario_count: #{scenario_count} parsed[scenario_count][i]: #{parsed[scenario_count][i]}"
      scenario_name_org = parsed[scenario_count][i]
      scenario_name = parsed[scenario_count][i].gsub!(/\A"|"\Z/, '')
      if scenario_name.nil?
        scenario_name = scenario_name_org
      end
      scenario_start_date = parsed[scenario_count + 1][i]
      puts "scenario_name_org #{scenario_name_org} scenario_name #{scenario_name} scenario_start_date #{scenario_start_date}"
      active_scenarios << [scenario_name, scenario_start_date]
      scenario_count +=2
      break if parsed[scenario_count].nil?
    end
  end

  puts "active_scenarios: #{active_scenarios}"
  puts "------------------------------------------------------"
  puts "- Verify the path for creating output file(s) for case #{i}"
  puts "------------------------------------------------------"

  building_sync_file_path = File.dirname(csv_file_path) + "/" + base_dir
  out_path = File.expand_path("../#{NAME_OF_OUTPUT_DIR}/SimulationFiles/#{File.basename(building_sync_file_path, File.extname(building_sync_file_path))}/", File.dirname(__FILE__))

  puts "out_path: #{out_path}"

  puts "------------------------------------------------------"
  puts "- Create hash for matching measure name and timeseries file for case #{i}"
  puts "------------------------------------------------------"
  # searching for report.csv file under each building folder and creating a hash where "measure name" and "path to the corresponding report.csv file" is matched
  csvs = Hash.new
  Dir.glob("#{out_path}/**/**/report.csv").each do |csv|
    measure_name = csv.split(File::Separator)[-3]
    puts "adding entry to hash: #{measure_name} -- #{csv}"
    csvs[measure_name] = csv
  end


  puts "------------------------------------------------------"
  puts "- Create/stich synthetic timeseries data for case #{i}"
  puts "------------------------------------------------------"
  current_scenario = Array.new
  date_array = start_date.split('/')
  start_date = Time.local(date_array[2],date_array[0],date_array[1])
  puts "start_date: #{start_date}"
  end_date_array = end_date.split('/')
  end_date = Time.local(end_date_array[2],end_date_array[0],end_date_array[1])

  scenario_counter = 0
  current_scenario = active_scenarios[scenario_counter]
  current_scenario_name = current_scenario[0]
  current_path = csvs[current_scenario_name]
  puts "current_scenario: #{current_scenario}"
  puts "current_scenario_name: #{current_scenario_name}"
  puts "current_path: #{current_path}"
  file = File.open current_path
  values = file.to_a
  puts "values[0]: #{values[0]}"

  scenario_counter = 1
  next_scenario = active_scenarios[scenario_counter]
  # initialize the headers
  CSV.open(out_path + "/#{base_dir}-#{i}.csv", "wb") do |csv|
    csv << ["", "Building-Smart-Meter-Export"]
    csv << ["", "Realization Name: #{name}"]
    csv << ["", "Export Date: #{Time.now.strftime("%m/%d/%Y %H:%M")}"]
    csv << [""]
    csv << ["Timestamp", "Building_Id_#{building_id}_Electricity_[J]", "Building_Id_#{building_id}_NaturalGas_[J]", "Scenario"]
    counter = 0
    8760.times do
      current_date = start_date + (counter) * 3600
      #puts "next_scenario: #{next_scenario}"
      #puts "scenario_counter: #{scenario_counter} -- counter: #{counter} -- current_date: #{current_date}"
      if next_scenario.nil?
        date_array =  end_date_array
      else
        date_array = next_scenario[1].split('/')
      end
      if current_date < Time.local(date_array[2],date_array[0],date_array[1]) + 3600 * 23 + 60 * 59 + 59
        current_values = values[counter + 1]
      elsif active_scenarios.count > scenario_counter
        puts "sencario count: #{active_scenarios.count} scenario:_counter: #{scenario_counter}"
        current_scenario = active_scenarios[scenario_counter]
        current_scenario_name = current_scenario[0]
        current_path = csvs[current_scenario_name]
        file.close
        puts "current_scenario: #{current_scenario_name} current_path: #{current_path}"
        file = File.open current_path
        values = file.to_a
        current_values = values[counter + 1]
        scenario_counter += 1
        next_scenario = active_scenarios[scenario_counter]
      end
      if(current_values.nil?)
        csv << [current_date.strftime("%m/%d/%Y %H:%M"), "", "", current_scenario[0]]
      else
        csv << [current_date.strftime("%m/%d/%Y %H:%M"), current_values.split(',')[0], current_values.split(',')[1], current_scenario[0]]
      end
      counter += 1
    end
  end
  file.close
end


