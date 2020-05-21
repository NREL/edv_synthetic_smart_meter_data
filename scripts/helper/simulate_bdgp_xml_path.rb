require 'openstudio'
require 'openstudio/extension'
require 'openstudio/model_articulation/os_lib_model_generation_bricr'
require 'buildingsync'
require 'buildingsync/translator'
require_relative '../constants'
require 'openstudio-occupant-variability'
require 'openstudio-variability'


def simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path, ddy_file_path, baseline_only, occ_var, non_routine_var)
  simulation_file_path = File.join(File.expand_path(NAME_OF_OUTPUT_DIR), SIM_FILES_DIR)
  if !File.exist?(simulation_file_path)
    FileUtils.mkdir_p(simulation_file_path)
  end

  out_path = File.expand_path("#{simulation_file_path}/#{File.basename(xml_file_path, File.extname(xml_file_path))}/", File.dirname(__FILE__))
  out_xml = File.expand_path("#{simulation_file_path}/#{File.basename(xml_file_path)}", File.dirname(__FILE__))
  root_dir = File.expand_path('../..', File.dirname(__FILE__))

  begin
    translator = BuildingSync::Translator.new(xml_file_path, out_path, epw_file_path, standard, false)
    translator.add_measure_path("#{root_dir}/lib/measures")
    translator.insert_reporting_measure('hourly_consumption_by_fuel_to_csv', 0)
    translator.write_osm(ddy_file_path)
    ###########################################################################################
    # This block of code is a work-around for avoiding leap year issue in occupant simulator.
    # This block should be removed once the issue is resolved on occupant simulator side.
    ###########################################################################################
    puts out_path
    m = OpenStudio::Model::Model.load(File.join(out_path, 'in.osm'))
    m = m.get
    yr = 2019
    m.setCalendarYear(yr)
    m.save(File.join(out_path, 'in.osm'), true)
    m2 = OpenStudio::Model::Model.load(File.join(out_path, 'in.osm'))
    m2 = m2.get
    puts "Calendar year set to: #{m2.assumedYear}"
    ###########################################################################################
    if occ_var
      occupant_variability_instance = OpenStudio::OccupantVariability::Extension.new
      translator.add_measure_path(occupant_variability_instance.measures_dir)
      translator.insert_model_measure('Occupancy_Simulator_os', 0)
      translator.insert_model_measure('create_lighting_schedule_from_occupant_count', 0)
      translator.insert_model_measure('create_mels_schedule_from_occupant_count', 0)
      translator.insert_model_measure('update_hvac_setpoint_schedule', 0)
    end

    if non_routine_var
      variability_instance = OpenStudio::Variability::Extension.new
      translator.add_measure_path(variability_instance.measures_dir)

      ## 1. Demand response measures
      # translator.insert_model_measure('DR_add_ice_storage_lgoffice_os', 0)
      # translator.insert_model_measure('DR_GTA_os', 0)
      # translator.insert_model_measure('DR_Lighting_os', 0)
      # translator.insert_model_measure('DR_MELs_os', 0)
      # translator.insert_model_measure('DR_Precool_Preheat_os', 0)

      ## 2. Faulty operation measures
      translator.insert_energyplus_measure('Fault_AirHandlingUnitFanMotorDegradation_ep')
      translator.insert_energyplus_measure('Fault_BiasedEconomizerSensorMixedT_ep')
      translator.insert_energyplus_measure('Fault_BiasedEconomizerSensorOutdoorRH_ep')
      translator.insert_energyplus_measure('Fault_BiasedEconomizerSensorOutdoorT_ep')
      translator.insert_energyplus_measure('Fault_BiasedEconomizerSensorReturnRH_ep')
      translator.insert_energyplus_measure('Fault_BiasedEconomizerSensorReturnT_ep')
      # translator.insert_energyplus_measure('Fault_CondenserFanDegradation_ep') # Fail
      # translator.insert_energyplus_measure('Fault_CondenserFouling_ep') # Fail
      translator.insert_model_measure('Fault_DuctFouling_os')
      translator.insert_model_measure('Fault_EconomizerOpeningStuck_os')
      # translator.insert_energyplus_measure('Fault_EvaporatorFouling_ep') # Fail
      translator.insert_model_measure('Fault_ExcessiveInfiltration_os')
      translator.insert_model_measure('Fault_HVACSetbackErrorDelayedOnset_os')
      translator.insert_model_measure('Fault_HVACSetbackErrorEarlyTermination_os')
      translator.insert_model_measure('Fault_HVACSetbackErrorNoOvernightSetback_os')
      # translator.insert_model_measure('Fault_ImproperTimeDelaySettingInOccupancySensors_os') # long run time
      # translator.insert_model_measure('Fault_LightingSetbackErrorDelayedOnset_os') # long run time
      # translator.insert_model_measure('Fault_LightingSetbackErrorEarlyTermination_os')
      # translator.insert_model_measure('Fault_LightingSetbackErrorNoOvernightSetback_os')
      # translator.insert_energyplus_measure('Fault_LiquidLineRestriction_ep') # long run time
      # translator.insert_model_measure('Fault_NonStandardCharging_os') # Fail
      # translator.insert_model_measure('Fault_OversizedEquipmentAtDesign_os') # Stuck
      # translator.insert_energyplus_measure('Fault_PresenceOfNonCondensable_ep') # Stuck
      # translator.insert_energyplus_measure('Fault_ReturnAirDuctLeakages_ep') # Stuck
      # translator.insert_energyplus_measure('Fault_SupplyAirDuctLeakages_ep') # Fail
      # translator.insert_model_measure('Fault_ThermostatBias_os') # Fail
      translator.insert_energyplus_measure('Fault_thermostat_offset_ep')

    end

    translator.write_osws

    translator.run_osws(baseline_only)
    translator.gather_results(out_path, baseline_only)
    translator.save_xml(out_xml)
  rescue StandardError => e
    puts "Error occurred while processing #{xml_file_path} with message: #{e.message}"
  end
end

