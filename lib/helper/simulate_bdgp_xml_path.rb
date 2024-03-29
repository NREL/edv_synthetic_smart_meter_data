require 'openstudio'
require 'openstudio/extension'
require 'openstudio/model_articulation'
require 'buildingsync'
require 'buildingsync/translator'
require 'openstudio/occupant_variability'
require 'openstudio-variability'
require 'rexml/document'

require_relative '../constants'

def simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path, ddy_file_path, baseline_only, occ_var, non_routine_var)
  simulation_file_path = File.join(File.expand_path(WORKFLOW_OUTPUT_DIR), SIM_FILES_DIR)
  puts "<<<<<<------DEBUGGING------>>>>>> simulation file path: #{simulation_file_path}"
  if !File.exist?(simulation_file_path)
    FileUtils.mkdir_p(simulation_file_path)
  end

  out_path = File.expand_path("#{simulation_file_path}/#{File.basename(xml_file_path, File.extname(xml_file_path))}/", File.dirname(__FILE__))
  out_xml = File.basename(xml_file_path)
  root_dir = File.expand_path('../..', File.dirname(__FILE__))

  puts "<<<<<<------DEBUGGING------>>>>>> out_path file path: #{out_path}"
  puts "<<<<<<------DEBUGGING------>>>>>> out_xml file path: #{out_xml}"
  puts "<<<<<<------DEBUGGING------>>>>>> root_dir file path: #{root_dir}"

  begin
    translator = BuildingSync::Translator.new(xml_file_path, out_path, epw_file_path, standard, false)
    puts "<<<<<<------DEBUGGING------>>>>>> epw_file_path = #{epw_file_path}"
    facility = translator.get_facility
    facility.add_cb_modeled('Baseline')

    puts "<<<<<<------DEBUGGING------>>>>>> adding measure: HourlyConsumptionByFuelToCSV"
    measure_dir = 'HourlyConsumptionByFuelToCSV'
    measure_path = File.join(root_dir, 'lib', 'measures')
    translator.add_measure_path(measure_path)
    translator.insert_measure_into_workflow('ReportingMeasure', measure_dir, 0, {})
    puts "<<<<<<------DEBUGGING------>>>>>> conducting sizing run"
    translator.setup_and_sizing_run

    ###########################################################################################
    # This block of code is a work-around for avoiding leap year issue in occupant simulator.
    # This block should be removed once the issue is resolved on occupant simulator side.
    ###########################################################################################
    puts "<<<<<<------DEBUGGING------>>>>>> setting simulation year"
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
      translator.insert_measure_into_workflow('ModelMeasure', 'Occupancy_Simulator_os', 0, {})
      translator.insert_measure_into_workflow('ModelMeasure', 'create_lighting_schedule_from_occupant_count', 0, {})
      translator.insert_measure_into_workflow('ModelMeasure', 'create_mels_schedule_from_occupant_count', 0, {})
      translator.insert_measure_into_workflow('ModelMeasure', 'update_hvac_setpoint_schedule', 0, {})
    end

    unless non_routine_var.empty?
      variability_instance = OpenStudio::Variability::Extension.new
      translator.add_measure_path(variability_instance.measures_dir)

      ## 1. Demand response measures
      if NON_ROUTINE_VAR[:DR_GTA_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'DR_GTA_os', 0, {})
      end
      if NON_ROUTINE_VAR[:DR_Lighting_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'DR_Lighting_os', 0, {})
      end
      if NON_ROUTINE_VAR[:DR_MELs_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'DR_MELs_os', 0, {})
      end
      if NON_ROUTINE_VAR[:DR_Precool_Preheat_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'DR_Precool_Preheat_os', 0, {})
      end

      ## 2. Faulty operation measures
      if NON_ROUTINE_VAR[:Fault_AirHandlingUnitFanMotorDegradation_ep]
        translator.insert_measure_into_workflow('EnergyPlusMeasure', 'Fault_AirHandlingUnitFanMotorDegradation_ep', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_BiasedEconomizerSensorMixedT_ep]
        translator.insert_measure_into_workflow('EnergyPlusMeasure', 'Fault_BiasedEconomizerSensorMixedT_ep', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_BiasedEconomizerSensorOutdoorRH_ep]
        translator.insert_measure_into_workflow('EnergyPlusMeasure', 'Fault_BiasedEconomizerSensorOutdoorRH_ep', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_BiasedEconomizerSensorOutdoorT_ep]
        translator.insert_measure_into_workflow('EnergyPlusMeasure', 'Fault_BiasedEconomizerSensorOutdoorT_ep', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_BiasedEconomizerSensorReturnRH_ep]
        translator.insert_measure_into_workflow('EnergyPlusMeasure', 'Fault_BiasedEconomizerSensorReturnRH_ep', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_BiasedEconomizerSensorReturnT_ep]
        translator.insert_measure_into_workflow('EnergyPlusMeasure', 'Fault_BiasedEconomizerSensorReturnT_ep', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_DuctFouling_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'Fault_DuctFouling_os', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_EconomizerOpeningStuck_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'Fault_EconomizerOpeningStuck_os', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_ExcessiveInfiltration_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'Fault_ExcessiveInfiltration_os', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_HVACSetbackErrorDelayedOnset_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'Fault_HVACSetbackErrorDelayedOnset_os', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_HVACSetbackErrorEarlyTermination_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'Fault_HVACSetbackErrorEarlyTermination_os', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_HVACSetbackErrorNoOvernightSetback_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'Fault_HVACSetbackErrorNoOvernightSetback_os', 0, {})
      end
      if NON_ROUTINE_VAR[:Fault_thermostat_offset_ep]
        translator.insert_measure_into_workflow('EnergyPlusMeasure', 'Fault_thermostat_offset_ep', 0, {})
      end

      ## 3. Retrofit measures
      if NON_ROUTINE_VAR[:Retrofit_equipment_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'Retrofit_equipment_os', 0, {})
      end
      if NON_ROUTINE_VAR[:Retrofit_lighting_os]
        translator.insert_measure_into_workflow('ModelMeasure', 'Retrofit_lighting_os', 0, {})
      end
      if NON_ROUTINE_VAR[:Retrofit_exterior_wall_ep]
        translator.insert_measure_into_workflow('EnergyPlusMeasure', 'Retrofit_exterior_wall_ep', 0, {})
      end
      if NON_ROUTINE_VAR[:Retrofit_roof_ep]
        translator.insert_measure_into_workflow('EnergyPlusMeasure', 'Retrofit_roof_ep', 0, {})
      end

    end

    puts "<<<<<<------DEBUGGING------>>>>>> write osw"
    translator.write_osws
    puts "<<<<<<------DEBUGGING------>>>>>> run osw"
    translator.run_osws(baseline_only)
    puts "<<<<<<------DEBUGGING------>>>>>> gather results"
    translator.gather_results(m2.assumedYear, BASELINE_ONLY)
    puts "<<<<<<------DEBUGGING------>>>>>> prepare final XML"
    translator.prepare_final_xml
    translator.save_xml(out_xml)

  rescue StandardError => e
    puts "Error occurred while processing #{xml_file_path} with message: #{e.message}"
  end
end
