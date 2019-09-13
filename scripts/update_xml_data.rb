

require 'fileutils'
require 'parallel'
require 'open3'
require 'csv'
require 'date'
require 'rexml/document'

# require_relative '../spec/spec_helper'
require_relative '../scripts/helper/csv_monthly_data'

if ARGV[0].nil? || !File.exist?(ARGV[0]) || ARGV[1].nil? || !Dir.exist?(ARGV[1])
  puts 'usage: bundle exec ruby csv_to_xmls /path/to/meta/with/csv /path/to/xmlFolder'
  puts '.csv files only'
  exit(1)
end

def update_xml_file(xml_file, csv_month_class_collection, counter)
  ns = 'auc'
  doc = create_xml_file_object(xml_file)
  file_value_collection = []
  scenario_element = doc.elements["/#{ns}:BuildingSync/#{ns}:Facilities/#{ns}:Facility/#{ns}:Reports/#{ns}:Report/#{ns}:Scenarios/#{ns}:Scenario"]

  time_series_data = REXML::Element.new("#{ns}:TimeSeriesData")
  scenario_element.add_element(time_series_data)

  csv_month_class_collection.each do |single_csv_class|
    next unless single_csv_class.get_values[counter] > 0
    time_series = REXML::Element.new("#{ns}:TimeSeries")
    reading_type = REXML::Element.new("#{ns}:ReadingType")
    reading_type.text = 'Total'
    time_series_reading_quantity = REXML::Element.new("#{ns}:TimeSeriesReadingQuantity")
    time_series_reading_quantity.text = 'Energy'
    start_time_stamp = REXML::Element.new("#{ns}:StartTimeStamp")
    start_time_stamp.text = single_csv_class.start_time_stamp
    end_time_stamp = REXML::Element.new("#{ns}:EndTimeStamp")
    end_time_stamp.text = single_csv_class.end_time_stamp
    interval_frequency = REXML::Element.new("#{ns}:IntervalFrequency")
    interval_frequency.text = 'Month'
    interval_reading = REXML::Element.new("#{ns}:IntervalReading")
    interval_reading.text = single_csv_class.get_values[counter]

    time_series.add_element(reading_type)
    time_series.add_element(time_series_reading_quantity)
    time_series.add_element(start_time_stamp)
    time_series.add_element(end_time_stamp)
    time_series.add_element(interval_frequency)
    time_series.add_element(interval_reading)
    time_series_data.add_element(time_series)

    file_value_collection.push(single_csv_class.get_values[counter])
  end

  calculate_annual_value(file_value_collection, scenario_element)
  saveXML(xml_file, doc)
end

def calculate_annual_value(file_value_collection, scenario_element)
  ns = 'auc'
  annual_total_value = file_value_collection.inject(0, :+)
  annual_max_value = file_value_collection.max

  resource_uses = REXML::Element.new("#{ns}:ResourceUses")
  resource_use = REXML::Element.new("#{ns}:ResourceUse")
  energy_resource = REXML::Element.new("#{ns}:EnergyResource")
  energy_resource.text = 'Electricity'
  resource_units = REXML::Element.new("#{ns}:ResourceUnits")
  resource_units.text = 'kBtu'
  annual_fuel_use_native_units = REXML::Element.new("#{ns}:AnnualFuelUseNativeUnits")
  annual_fuel_use_native_units.text = annual_total_value
  annual_fuel_use_consistent_units = REXML::Element.new("#{ns}:AnnualFuelUseConsistentUnits")
  annual_fuel_use_consistent_units.text = unit_converted_value(annual_total_value)
  peak_resource_units = REXML::Element.new("#{ns}:PeakResourceUnits")
  peak_resource_units.text = 'kW'
  annual_peak_native_units = REXML::Element.new("#{ns}:AnnualPeakNativeUnits")
  annual_peak_native_units.text = annual_max_value
  annual_peak_consistent_units = REXML::Element.new("#{ns}:AnnualPeakConsistentUnits")
  annual_peak_consistent_units.text = annual_max_value

  scenario_element.add_element(resource_uses)
  resource_uses.add_element(resource_use)
  resource_use.add_element(energy_resource)
  resource_use.add_element(resource_units)
  resource_use.add_element(annual_fuel_use_native_units)
  resource_use.add_element(annual_fuel_use_consistent_units)
  resource_use.add_element(peak_resource_units)
  resource_use.add_element(annual_peak_native_units)
  resource_use.add_element(annual_peak_consistent_units)
end

def unit_converted_value(annual_total_value)
  if annual_total_value > 0
    annual_value_kwh = annual_total_value / 720
    return  annual_value_kwh * 3.41214163513307
  end
  0
end

def saveXML(filename, doc)
  File.open(filename, 'w') do |file|
    doc.write(file)
  end
end

def create_xml_file_object(xml_file_path)
  doc = nil
  File.open(xml_file_path, 'r') do |file|
    doc = REXML::Document.new(file)
  end
  doc
end

def create_monthly_csv_data(csv_row_collection)
  monthly_csv_obj = MonthlyData.new
  datetime = Date.parse csv_row_collection[0][0]
  monthly_csv_obj.update_start_time(datetime)
  monthly_csv_obj.update_year(datetime.year)
  monthly_csv_obj.update_month(datetime.month)
  monthly_csv_obj.update_end_time(csv_row_collection.last[0])

  csv_row_collection.each do |single_row|
    counter = 0
    single_row.each do |single_value|
      monthly_csv_obj.update_values(single_value, counter) if counter > 0
      counter += 1
    end
  end
  monthly_csv_obj
end

csv_row_collection = []
csv_month_class_collection = []

header_name = []
# csv_file_path = 'E:\Bricr\edv-experiment-1\spec\files\temp_open_utc.csv'
# xml_file_path = 'E:\Bricr\edv-experiment-1\Test_output\Bldg_Sync_Files'
csv_file_path = ARGV[0]
xml_file_path = ARGV[1]

if !csv_file_path.nil? && !csv_file_path.empty?
  csv_table = CSV.read(csv_file_path)
  header_name = csv_table[0]
  counter = 0
  csv_month_value = 0

  csv_table.each do |csv_row|
    if counter > 0
      datetime = Date.parse csv_row[0]

      if csv_month_value != datetime.month
        csv_month_value = datetime.month
        if csv_row_collection.count > 0
          csv_month_class_collection.push(create_monthly_csv_data(csv_row_collection))
          csv_row_collection.clear
        end
      end

      csv_row_collection.push(csv_row)

    end
    counter += 1
  end

  counter = 0
  header_name.each do |file_name|
    if counter > 0
      xml_file = File.expand_path("#{file_name}.xml", xml_file_path.to_s)
      if File.exist?(xml_file)
        update_xml_file(xml_file, csv_month_class_collection, counter)
      else
        p "file #{file_name} does not exist"
      end
    end
    counter += 1
  end
end




