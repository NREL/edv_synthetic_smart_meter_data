require_relative 'csv_monthly_data'

require 'fileutils'
require 'parallel'
require 'open3'
require 'csv'
require 'date'
require 'rexml/document'

class MeasuredDataCalculation

  def initialize
    # This is a stub, used for indexing
  end

  def add_measured_data_to_xml_file(xml_file, csv_month_class_collection, counter, annual_max)
    ns = 'auc'
    doc = create_xml_file_object(xml_file)
    file_consistent_value_collection = []
    file_native_value_collection = []
    file_peak_value_collection = []
    measured_scenario_element = nil
    scenario_elements = doc.elements["/#{ns}:BuildingSync/#{ns}:Facilities/#{ns}:Facility/#{ns}:Reports/#{ns}:Report/#{ns}:Scenarios"]
    scenario_elements.each do |scenario_element|
      begin
        measured_scenario_element = scenario_element if scenario_element.attributes['ID'] == 'Measured'
      rescue
#        puts "scenario issue found in #{xml_file} in scenario: #{scenario_element}"
#        puts "scenario_elements: #{scenario_elements}"
      end
    end
    if measured_scenario_element.nil?
      measured_scenario_element = REXML::Element.new("#{ns}:Scenario")
      measured_scenario_element.add_attribute('ID', 'Measured')
      scenario_name = REXML::Element.new("#{ns}:ScenarioName")
      scenario_name.text = 'Measured'
      measured_scenario_element.add_element(scenario_name)
      scenario_type = REXML::Element.new("#{ns}:ScenarioType")
      measured_scenario_element.add_element(scenario_type)
      package_of_measures = REXML::Element.new("#{ns}:PackageOfMeasures")
      scenario_type.add_element(package_of_measures)
      reference_case = REXML::Element.new("#{ns}:ReferenceCase")
      reference_case.add_attribute('IDref', 'Baseline')
      package_of_measures.add_element(reference_case)
      calculation_method = REXML::Element.new("#{ns}:CalculationMethod")
      package_of_measures.add_element(calculation_method)
      measured = REXML::Element.new("#{ns}:Measured")
      calculation_method.add_element(measured)
      other = REXML::Element.new("#{ns}:Other")
      measured.add_element(other)
      scenario_elements.add_element(measured_scenario_element)
    end
    time_series_data = REXML::Element.new("#{ns}:TimeSeriesData")
    measured_scenario_element.add_element(time_series_data)

    csv_month_class_collection.each do |single_csv_class|
      unless single_csv_class.get_total_values[counter].nil?
        next unless single_csv_class.get_total_values[counter] > 0
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
        interval_reading.text = single_csv_class.get_total_values[counter]

        time_series.add_element(reading_type)
        time_series.add_element(time_series_reading_quantity)
        time_series.add_element(start_time_stamp)
        time_series.add_element(end_time_stamp)
        time_series.add_element(interval_frequency)
        time_series.add_element(interval_reading)
        time_series_data.add_element(time_series)

        file_consistent_value_collection.push(single_csv_class.get_total_values[counter])
        file_native_value_collection.push(single_csv_class.get_native_values[counter])
      end
    end

    calculate_annual_value(file_consistent_value_collection, file_native_value_collection, measured_scenario_element, annual_max)

    save_xml(xml_file.gsub('Bldg_Sync_Files', 'Bldg_Sync_Files_w_Measured_Data'), doc)
  end

  def calculate_annual_value(file_consistent_value_collection, file_native_value_collection, scenario_element, annual_max)
    ns = 'auc'
    annual_total_value_kbtu = file_consistent_value_collection.inject(0, :+)
    annual_total_value_kwh = file_native_value_collection.inject(0, :+)
    annual_max_value_kbtu = file_consistent_value_collection.max
    annual_max_value_kwh = annual_max

    resource_uses = REXML::Element.new("#{ns}:ResourceUses")
    resource_use = REXML::Element.new("#{ns}:ResourceUse")
    energy_resource = REXML::Element.new("#{ns}:EnergyResource")
    energy_resource.text = 'Electricity'
    resource_units = REXML::Element.new("#{ns}:ResourceUnits")
    resource_units.text = 'MMBtu'

    # annual fuel use native units: Sum of all time series values for the past year, in the original units. (units/yr)
    annual_fuel_use_native_units = REXML::Element.new("#{ns}:AnnualFuelUseNativeUnits")
    annual_fuel_use_native_units.text = annual_total_value_kwh

    # annual fuel use consistent units: 
    # Sum of all time series values for a particular or typical year, converted into million Btu of site energy. (MMBtu/yr)
    annual_fuel_use_consistent_units = REXML::Element.new("#{ns}:AnnualFuelUseConsistentUnits")
    annual_fuel_use_consistent_units.text = annual_total_value_kbtu / 1000
    peak_resource_units = REXML::Element.new("#{ns}:PeakResourceUnits")

    # annual peak native units: Largest 15-min peak
    peak_resource_units.text = 'kW'
    annual_peak_native_units = REXML::Element.new("#{ns}:AnnualPeakNativeUnits")
    annual_peak_native_units.text = annual_max_value_kwh

    # annual peak consistent units: Largest 15-min peak (kW)
    annual_peak_consistent_units = REXML::Element.new("#{ns}:AnnualPeakConsistentUnits")
    annual_peak_consistent_units.text = annual_max_value_kwh

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

  def save_xml(filename, doc)
    unless Dir.exist?(File.dirname(filename))
      FileUtils.mkdir_p(File.dirname(filename))
    end

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

  def create_monthly_csv_data(csv_row_collection, header, max)
    monthly_csv_obj = MonthlyData.new
    datetime = Date.parse csv_row_collection[0][0]
    monthly_csv_obj.update_start_time(datetime)
    monthly_csv_obj.update_year(datetime.year)
    monthly_csv_obj.update_month(datetime.month)
    monthly_csv_obj.update_end_time(csv_row_collection.last[0])

    (1...header.length).each do |headers|
      (0...csv_row_collection.length).each do |hourly|
        monthly_csv_obj.update_monthly_values(csv_row_collection, hourly, headers)
      end
      max.push monthly_csv_obj.get_monthly_peak_values
    end

    csv_row_collection.each do |single_row|
      counter = 0
      single_row.each do |single_value|
        monthly_csv_obj.update_total_values(single_value, counter) if counter > 0
        counter += 1
      end
    end
    monthly_csv_obj
  end

  def initiate_measure_data_calculation(csv_file_path, xml_file_path)
    csv_row_collection = []
    csv_month_class_collection = []

    csv_table = CSV.read(csv_file_path)
    header_name = csv_table[0]
    csv_month_value = 0
    csv_table.shift
    months = []

    csv_table.each do |csv_row|
        datetime = Date.parse csv_row[0]
        if csv_month_value != datetime.month
          csv_month_value = datetime.month
          months.push(csv_month_value)
        end
    end

    # Monthly peak values for individual buildings
    monthly_max = []
    months.each do |month|
      csv_table.each do |row|
        if Date.parse(row[0]).month == month
          csv_row_collection.push(row)
        end
      end
        csv_month_class_collection.push(create_monthly_csv_data(csv_row_collection, header_name, monthly_max))
        csv_row_collection.clear
    end

    # Annual peak values for individual buildings
    annual_max = []
    one = []
    (0...header_name.drop(1).length).each do |header|
      one[header] = []
      (header...monthly_max.length).step(header_name.drop(1).length).each do |maxes|
        one[header].push monthly_max[maxes]
      end
      annual_max.push one[header].max
    end

    # Create BuildingSync xml files with measured data
    completed_files = 0
    header_name.drop(1).each do |file_name|
      xml_file = File.expand_path("#{file_name}.xml", xml_file_path.to_s)
      if File.exist?(xml_file)
        (0...csv_month_class_collection.length).each do |counter|
          add_measured_data_to_xml_file(xml_file, csv_month_class_collection, counter, annual_max[completed_files])
        end
        completed_files += 1
      else
        puts "File #{file_name} does not exist"
      end
    end
    puts "Successfully processed #{completed_files} of #{header_name.drop(1).length} possible files"
  end
end
