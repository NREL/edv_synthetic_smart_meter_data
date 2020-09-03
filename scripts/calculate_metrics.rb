require_relative 'constants'
require_relative 'helper/csv_monthly_data'
require_relative 'helper/metrics_calculation'
require 'rexml/document'

if ARGV[0].nil? || !Dir.exist?(ARGV[0])
  puts 'usage: bundle exec ruby calculate_metrics /path/to/simulated/data'
  exit(1)
end

indir = ARGV[0]
# output directory
# outdir = "./#{NAME_OF_OUTPUT_DIR}/BldgSync_Files"
# FileUtils.mkdir_p(outdir) unless File.exist?(outdir)

ns = 'auc'
puts "looking at directory: #{indir}"
puts "found #{Dir.glob(File.join(indir, "*.xml")).count} files "

def get_electric_resource_use_id(scenario_element, ns)
  resource_uses = scenario_element.elements["#{ns}:ResourceUses"]
  if resource_uses.nil?
    puts scenario_element.elements["#{ns}:ScenarioName"].to_s + " has nil ResourceUses"
    return nil
  end
  resource_uses.each do |resource_use_element|
    if resource_use_element.elements["#{ns}:EnergyResource"].text == "Electricity"
      return resource_use_element.attributes['ID']
    end
  end
end

def get_floor_area_value(doc, ns)
  measured_floor_element = nil
  floor_areas = doc.elements["/#{ns}:BuildingSync/#{ns}:Facilities/#{ns}:Facility/#{ns}:Sites/#{ns}:Site/#{ns}:Buildings/#{ns}:Building/#{ns}:FloorAreas"]
  floor_areas.each do |floor_element|
    begin
      if floor_element.elements["#{ns}:FloorAreaType"].text == 'Gross'
        measured_floor_element = floor_element
      end
    rescue
      puts "scenario issue found floor_areas: #{floor_areas}"
    end
  end
  return measured_floor_element.elements["#{ns}:FloorAreaValue"].text.to_f
end

def read_time_series_data(scenario_element, ns, resource_use_id = nil)
  monthly_data = MonthlyData.new
  counter = 0
  time_series_data = scenario_element.elements["#{ns}:TimeSeriesData"]
  time_series_data.each do |time_series|
    if resource_use_id.nil? || time_series.elements["#{ns}:ResourceUseID"].attributes['IDref'] == resource_use_id
      datetime = time_series.elements["#{ns}:StartTimestamp"].text
      monthly_data.add_start_date_string(datetime)
      #monthly_measured_data.update_year(datetime.year)
      #monthly_measured_data.update_month(datetime.month)
      #monthly_measured_data.update_end_time(time_series.elements["#{ns}:EndTimestamp"].text)
      monthly_data.update_total_values(time_series.elements["#{ns}:IntervalReading"].text, counter)
      counter += 1
    end
  end
  return monthly_data
end

Dir.glob(File.join(indir, "/*.xml")).each do |xml_file_path|
  # open the xml file
  doc = nil
  File.open(xml_file_path, 'r') do |xml_file_path|
    doc = REXML::Document.new(xml_file_path)

    eui_mea_count = 0
    eui_sim_count = 0
    cvrmse_count = 0
    nmbe_count = 0

    floor_area = get_floor_area_value(doc, ns)
    monthly_measured_data = nil
    # first we get the measured scenario
    scenario_elements = doc.elements["/#{ns}:BuildingSync/#{ns}:Facilities/#{ns}:Facility/#{ns}:Reports/#{ns}:Report/#{ns}:Scenarios"]
    # for the first pass we just look for the measured scenario
    scenario_elements.each do |scenario_element|
      if scenario_element.attributes['ID'] == 'Measured'
        monthly_measured_data = read_time_series_data(scenario_element, ns)

        eui = MetricsCalc.calculate_eui_value(monthly_measured_data.get_summary, floor_area)
        eui_mea_count += MetricsCalc.add_eui(scenario_element, eui, ns)
      end
    end

    # the second pass we look for simulated scenarios
    scenario_elements.each do |scenario_element|
      if scenario_element.attributes['ID'] != 'Measured'
        electricity_resource_use_id = get_electric_resource_use_id(scenario_element, ns)
        if electricity_resource_use_id

          monthly_simulated_data = read_time_series_data(scenario_element, ns, electricity_resource_use_id)

          eui = MetricsCalc.calculate_eui_value(monthly_simulated_data.get_summary, floor_area)
          eui_sim_count += MetricsCalc.add_eui(scenario_element, eui, ns)

          cvrmse = MetricsCalc.calculate_cvrmse(monthly_measured_data, monthly_simulated_data)
          cvrmse_count += MetricsCalc.add_user_defined_field(scenario_element, "CVRMSE", cvrmse, ns)

          nmbe = MetricsCalc.calculate_nmbe(monthly_measured_data, monthly_simulated_data)
          nmbe_count += MetricsCalc.add_user_defined_field(scenario_element, "NMBE", nmbe, ns)
        end
      end
    end

    new_xml_file_path = File.absolute_path(xml_file_path).gsub("#{SIM_FILES_DIR}", "#{CALC_METRICS_DIR}")
    # save the file as
    unless Dir.exist?(File.dirname(new_xml_file_path))
      FileUtils.mkdir_p(File.dirname(new_xml_file_path))
    end

    File.open(new_xml_file_path, 'w') do |file|
      doc.write(file)
    end

    puts "successfully added the following metrics: Measured EUI: #{eui_mea_count}, Simulated EUI: #{eui_sim_count}, CVRMSE: #{cvrmse_count} and NMBE: #{nmbe_count} to file #{new_xml_file_path}"
  end
end
