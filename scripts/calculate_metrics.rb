require_relative 'constants'
require_relative 'helper/csv_monthly_data'
require_relative 'helper/metrics_calculation'
require 'rexml/document'
require 'fileutils'
require 'date'

if ARGV[0].nil? || !Dir.exist?(ARGV[0])
  puts 'usage: bundle exec rake calculate_metrics /path/to/simulated/data'
  exit(1)
end

indir = ARGV[0]
ns = 'auc'

if Dir.glob(File.join(indir, "**/*.xml")).count == 0
  puts "No BuildingSync files found in directory"
end

def get_electric_resource_use_id(scenario_element, ns)
  resource_uses = scenario_element.elements["#{ns}:ResourceUses"]
  return nil if resource_uses.nil?
  resource_uses.each_element do |resource_use_element|
    if resource_use_element.elements["#{ns}:EnergyResource"].text == "Electricity"
      return resource_use_element.attributes['ID']
    end
  end
end

def get_floor_area_value(doc, ns)
  measured_floor_element = nil
  floor_areas = doc.elements["/#{ns}:BuildingSync/#{ns}:Facilities/#{ns}:Facility/#{ns}:Sites/#{ns}:Site/#{ns}:Buildings/#{ns}:Building/#{ns}:FloorAreas"]
  if !floor_areas.nil?
    floor_areas.each_element do |floor_element|
      if floor_element.elements["#{ns}:FloorAreaType"].text == 'Gross'
        measured_floor_element = floor_element
      end
    end

    return measured_floor_element.elements["#{ns}:FloorAreaValue"].text.to_f
  end
end

def read_time_series_data(scenario_element, ns, resource_use_id = nil, interval_frequency = "Month")
  monthly_data = MonthlyData.new
  counter = 0
  time_series_data = scenario_element.elements["#{ns}:TimeSeriesData"]

  # process hourly data:
  # TODO: apply multi-year data, BSync only records 1 year of time-series data
  if interval_frequency == "Hour"
    total_value = Array.new(12) {0}
    ts_data = REXML::Element.new("#{ns}:TimeSeriesData")
    time_series_data.each_element do |ts|
      total_value[DateTime.strptime(ts.elements["#{ns}:StartTimestamp"].text, "%m-%d-%y %H:%M").month - 1] += ts.elements["#{ns}:IntervalReading"].text.to_f
    end
    total_value.each_with_index do |value, i|
      time_series = REXML::Element.new("#{ns}:TimeSeries")
      monthly_interval_frequency = REXML::Element.new("#{ns}:IntervalFrequency")
      monthly_interval_reading = REXML::Element.new("#{ns}:IntervalReading")
      monthly_interval_frequency = "Month"
      monthly_interval_reading.text = total_value[i]
      time_series.add_element(monthly_interval_reading)

      ts_data.add_element(time_series)
    end
    time_series_data = ts_data
  end

  time_series_data.each_element do |time_series|
    if resource_use_id.nil? || time_series.elements["#{ns}:ResourceUseID"].attributes['IDref'] == resource_use_id
      monthly_data.update_total_values(time_series.elements["#{ns}:IntervalReading"].text, counter)
      counter += 1
    end
  end
  return monthly_data
end

Dir.glob(File.join(indir, "**/*.xml")).each do |xml_file_path|
  puts "#{xml_file_path}"
  doc = nil
  File.open(xml_file_path, 'r') do |xml_file_path|
    doc = REXML::Document.new(xml_file_path)

    eui_mea_count = 0
    eui_sim_count = 0
    cvrmse_count = 0
    nmbe_count = 0

    annual_electricity_use_consistent_units = 0
    annual_gas_use_consistent_units = 0

    floor_area = get_floor_area_value(doc, ns)
    monthly_measured_data = nil
    scenario_elements = doc.elements["/#{ns}:BuildingSync/#{ns}:Facilities/#{ns}:Facility/#{ns}:Reports/#{ns}:Report/#{ns}:Scenarios"]
    begin
      scenario_elements.each_element do |scenario_element|
        if scenario_element.attributes['ID'] == 'Measured'
          ts_element = scenario_element.elements["#{ns}:TimeSeriesData"].elements().to_a.first()
          interval_frequency = ts_element.elements["#{ns}:IntervalFrequency"].text
          monthly_measured_data = read_time_series_data(scenario_element, ns, nil, interval_frequency)
        else
          electricity_resource_use_id = get_electric_resource_use_id(scenario_element, ns)
          if electricity_resource_use_id

            monthly_simulated_data = read_time_series_data(scenario_element, ns, electricity_resource_use_id)

            if !scenario_element.elements["#{ns}:AnnualFuelUseConsistentUnits"]
              scenario_element.elements["#{ns}:TimeSeriesData"].each_element do |time_series|
                if time_series.attributes['ID'].include? "Electricity"
                  annual_electricity_use_consistent_units += time_series.elements["#{ns}:IntervalReading"].text.to_f

                  next if time_series.attributes['ID'].include? "DEC"
                elsif time_series.attributes['ID'].include? "NaturalGas"
                  annual_gas_use_consistent_units += time_series.elements["#{ns}:IntervalReading"].text.to_f if time_series.attributes['ID'].include? "NatualGas"

                  next if time_series.attributes['ID'].include? "DEC"
                end
              end

              # add an element AnnualFuelUseConsistentUnits
              annual_fuel_use_consistent_units = REXML::Element.new('auc:AnnualFuelUseConsistentUnits')
              annual_fuel_use_consistent_units.text = (annual_electricity_use_consistent_units * 3.412).to_s
              scenario_element.add_element(annual_fuel_use_consistent_units)
            end

            eui = Metrics.calculate_eui_value(scenario_element.elements["#{ns}:AnnualFuelUseConsistentUnits"].text.to_f, floor_area)
            eui_sim_count += Metrics.add_eui(scenario_element, eui, ns)

            cvrmse = Metrics.calculate_cvrmse(monthly_measured_data, monthly_simulated_data)
            cvrmse_count += Metrics.add_user_defined_field(scenario_element, "CVRMSE", cvrmse, ns)

            nmbe = Metrics.calculate_nmbe(monthly_measured_data, monthly_simulated_data)
            nmbe_count += Metrics.add_user_defined_field(scenario_element, "NMBE", nmbe, ns)
          end
        end
      end
    rescue NoMethodError => e
      puts "Error #{e} occurred while processing #{File.basename(xml_file_path)}"
    end

    new_xml_file_path = File.absolute_path(xml_file_path).gsub("#{SIM_FILES_DIR}", "#{CALC_METRICS_DIR}")
    unless Dir.exist?(File.dirname(new_xml_file_path))
      FileUtils.mkdir_p(File.dirname(new_xml_file_path))
    end

    File.open(new_xml_file_path, 'w') do |file|
      doc.write(file)
    end

    puts "successfully added the following metrics: Measured EUI: #{eui_mea_count}, Simulated EUI: #{eui_sim_count}, CVRMSE: #{cvrmse_count} and NMBE: #{nmbe_count} to file #{File.basename(new_xml_file_path)}"
  end
end
