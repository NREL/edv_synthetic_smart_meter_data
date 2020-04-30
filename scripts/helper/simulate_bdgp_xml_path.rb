require 'openstudio/extension'
require 'openstudio/model_articulation/os_lib_model_generation_bricr'
require 'buildingsync'
require 'buildingsync/translator'
require_relative '../constants'


def simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path, ddy_file_path, baseline_only)
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
    translator.write_osws

    translator.run_osws(baseline_only)
    translator.gather_results_and_save_xml(out_path, baseline_only)
    # translator.gather_results_and_save_xml(out_path, )
    translator.write_parameters_to_xml(out_xml)
  rescue StandardError => e
    puts "Error occurred while processing #{xml_file_path} with message: #{e.message}"
  end
end