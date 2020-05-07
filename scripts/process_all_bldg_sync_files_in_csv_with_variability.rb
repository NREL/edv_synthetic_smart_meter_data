# Run a BuildingSync XML file to generate synthetic smart meter data

require 'openstudio/extension'
require 'openstudio/model_articulation/os_lib_model_generation_bricr'
require 'buildingsync'
require 'buildingsync/translator'
require 'openstudio-occupant-variability'
require 'openstudio-variability'


require_relative 'constants'

start = Time.now
puts "Simulation script started at #{start}"
baseline_only = true

OpenStudio::Extension::Extension::DO_SIMULATIONS = true
OpenStudio::Extension::Extension::NUM_PARALLEL = 1
BUILDINGS_PARALLEL = 5
BuildingSync::Extension::SIMULATE_BASELINE_ONLY = baseline_only

if ARGV[0].nil?
  puts 'usage: bundle exec ruby process_all_bldg_sync_files_in_csv.rb path/to/csv/file'
  puts "must provide a .csv file"
  exit(1)
end

bldg_sync_file_dir = "#{NAME_OF_OUTPUT_DIR}/Bldg_Sync_Files"
if !ARGV[1].nil?
  #bldg_sync_file_dir = File.join("../", ARGV[1])
  bldg_sync_file_dir = File.expand_path(ARGV[1])
end

def simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path, ddy_file_path, baseline_only)
  simulation_file_path = File.join(File.expand_path(NAME_OF_OUTPUT_DIR), 'Simulation_Files')
  if !File.exist?(simulation_file_path)
    FileUtils.mkdir_p(simulation_file_path)
  end

  begin
    out_path = File.expand_path("#{simulation_file_path}/#{File.basename(xml_file_path, File.extname(xml_file_path))}/", File.dirname(__FILE__))
    out_xml = File.expand_path("#{simulation_file_path}/#{File.basename(xml_file_path)}", File.dirname(__FILE__))

    root_dir = File.expand_path('..', File.dirname(__FILE__))

    translator = BuildingSync::Translator.new(xml_file_path, out_path, epw_file_path, standard, false)

    # Add occupant variability measures (stochastic occupancy -> lighting -> MELs -> HVAC thermostat setpoint)
    occupant_variability_instance = OpenStudio::OccupantVariability::Extension.new
    translator.add_measure_path(occupant_variability_instance.measures_dir)
    # TODO: Update occupancy simulator to generate correct date for leap year
    # translator.insert_model_measure('Occupancy_Simulator_os', 0)
    # translator.insert_model_measure('create_lighting_schedule_from_occupant_count', 0)
    # translator.insert_model_measure('create_mels_schedule_from_occupant_count', 0)
    translator.insert_model_measure('update_hvac_setpoint_schedule', 0)  #Independent from occupancy schedule

    # Add non-routine event variability measures (DR, Retrofit, Faulty Operation)
    variability_instance = OpenStudio::Variability::Extension.new
    translator.add_measure_path(variability_instance.measures_dir)
    ## 1. Demand response measures
    # translator.insert_model_measure('DR_add_ice_storage_lgoffice_os', 0)
    # translator.insert_model_measure('DR_GTA_os', 0)
    # translator.insert_model_measure('DR_Lighting_os', 0)
    # translator.insert_model_measure('DR_MELs_os', 0)
    # translator.insert_model_measure('DR_Precool_Preheat_os', 0)

    ## 2. Faulty operation measures
    # translator.insert_energyplus_measure('Fault_AirHandlingUnitFanMotorDegradation_ep')
    # translator.insert_energyplus_measure('Fault_BiasedEconomizerSensorMixedT_ep')
    # translator.insert_energyplus_measure('Fault_BiasedEconomizerSensorOutdoorRH_ep')
    # translator.insert_energyplus_measure('Fault_BiasedEconomizerSensorOutdoorT_ep')
    # translator.insert_energyplus_measure('Fault_BiasedEconomizerSensorReturnRH_ep')
    # translator.insert_energyplus_measure('Fault_BiasedEconomizerSensorReturnT_ep')
    # translator.insert_energyplus_measure('Fault_CondenserFanDegradation_ep')
    # translator.insert_energyplus_measure('Fault_CondenserFouling_ep')
    # translator.insert_model_measure('Fault_DuctFouling_os')
    # translator.insert_model_measure('Fault_EconomizerOpeningStuck_os')
    # translator.insert_energyplus_measure('Fault_EvaporatorFouling_ep')
    # translator.insert_model_measure('Fault_ExcessiveInfiltration_os')
    # translator.insert_model_measure('Fault_HVACSetbackErrorDelayedOnset_os')
    # translator.insert_model_measure('Fault_HVACSetbackErrorEarlyTermination_os')
    # translator.insert_model_measure('Fault_HVACSetbackErrorNoOvernightSetback_os')
    # translator.insert_model_measure('Fault_ImproperTimeDelaySettingInOccupancySensors_os')
    # translator.insert_model_measure('Fault_LightingSetbackErrorDelayedOnset_os')
    # translator.insert_model_measure('Fault_LightingSetbackErrorEarlyTermination_os')
    # translator.insert_model_measure('Fault_LightingSetbackErrorNoOvernightSetback_os')
    # translator.insert_energyplus_measure('Fault_LiquidLineRestriction_ep')
    # translator.insert_model_measure('Fault_NonStandardCharging_os')
    # translator.insert_model_measure('Fault_OversizedEquipmentAtDesign_os')
    # translator.insert_energyplus_measure('Fault_PresenceOfNonCondensable_ep')
    # translator.insert_energyplus_measure('Fault_ReturnAirDuctLeakages_ep')
    # translator.insert_energyplus_measure('Fault_SupplyAirDuctLeakages_ep')
    # translator.insert_model_measure('Fault_ThermostatBias_os')
    # translator.insert_energyplus_measure('Fault_thermostat_offset_ep')

    ## 3. Retrofit measures
    translator.insert_model_measure('Retrofit_equipment_os', 0)
    translator.insert_model_measure('Retrofit_lighting_os', 0)
    translator.insert_energyplus_measure('Retrofit_exterior_wall_ep', 0)
    translator.insert_energyplus_measure('Retrofit_roof_ep', 0)

    # Add other measures
    translator.add_measure_path("#{root_dir}/lib/measures")
    translator.insert_reporting_measure('hourly_consumption_by_fuel_to_csv', 0)
    translator.write_osm(ddy_file_path)
    translator.write_osws

    osws = Dir.glob("#{out_path}/**/in.osw")
    if BuildingSync::Extension::SIMULATE_BASELINE_ONLY
      osws = Dir.glob("#{out_path}/Baseline/in.osw")
    end

    puts "osws: #{osws}"
    puts "SIMULATE_BASELINE_ONLY: #{BuildingSync::Extension::SIMULATE_BASELINE_ONLY}"
    runner = OpenStudio::Extension::Runner.new(root_dir)
    runner.run_osws(osws, num_parallel=OpenStudio::Extension::Extension::NUM_PARALLEL)

    translator.gather_results(out_path, baseline_only)
    translator.save_xml(out_xml)
  rescue StandardError => e
    puts "Error occurred while processing #{xml_file_path} with message: #{e.message}"
  end


end



########################################################################################################################
# Main process
########################################################################################################################
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
  log.puts("processing xml_file: #{xml_file} - standard: #{standard} - epw_file: #{epw_file}")

  xml_file_path = File.expand_path("#{bldg_sync_file_dir}/#{xml_file}/", File.dirname(__FILE__))
  out_path = File.expand_path("#{bldg_sync_file_dir}/#{File.basename(xml_file, File.extname(xml_file))}/", File.dirname(__FILE__))

  epw_file_path = ''
  if File.exist?(epw_file)
    epw_file_path = epw_file
  else
    epw_file_path = File.expand_path("../scripts/#{epw_file}/", File.dirname(__FILE__))
  end

  ddy_file_path = ''
  if !ddy_file.nil?
    ddy_file_path = ddy_file
  else
    ddy_file = 'temporary.ddy'
    ddy_file_path = File.expand_path("../scripts/#{ddy_file}/", File.dirname(__FILE__))
  end
  puts "xml? #{xml_file}"

  puts '= ' * 50

  result = simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path, ddy_file_path, baseline_only)

  # #puts "...completed: #{result} and osm file exist: #{File.exist?("#{out_path}/in.osm")}"
  # log.puts("#{result} and osm file exist: #{File.exist?("#{out_path}/in.osm")}")
  #
  # output_dirs = []
  # Dir.glob("#{out_path}/**/") { |output_dir| output_dirs << output_dir }
  # output_dirs.each do |output_dir|
  #   if !output_dir.include? "/SR"
  #     if output_dir != out_path
  #       idf_file = File.join(output_dir, "/in.idf")
  #       sql_file = File.join(output_dir, "/results.json")
  #       if File.exist?(idf_file) && !File.exist?(sql_file)
  #         log.puts("...ERROR: #{sql_file} does not exist, simulation was unsuccessful}")
  #         log.flush
  #       end
  #     end
  #   end
  # end




end
log.close

finish = Time.now
puts "Simulation script completed at #{finish}"
diff = finish - start
puts "Simulation script completed in #{diff} seconds, #{(diff.to_f/60).round(2)} minutes, #{(diff.to_f/3600).round(2)} hours, #{(diff.to_f/3600/24).round(2)} days"
