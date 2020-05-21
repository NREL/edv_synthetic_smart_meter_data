require 'openstudio'
require 'openstudio/extension'
require 'openstudio/model_articulation/os_lib_model_generation_bricr'
require 'buildingsync'
require 'buildingsync/translator'
require_relative '../constants'
require 'openstudio-occupant-variability'


def simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path, ddy_file_path, baseline_only, occ_var)
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

    translator.write_osws

    translator.run_osws(baseline_only)
    translator.gather_results(out_path, baseline_only)
    translator.save_xml(out_xml)
  rescue StandardError => e
    puts "Error occurred while processing #{xml_file_path} with message: #{e.message}"
  end
end
