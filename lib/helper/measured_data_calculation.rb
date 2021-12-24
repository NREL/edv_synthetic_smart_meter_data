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

  def add_measured_data_to_xml_file(xml_file, interval, csv_month_class_collection, counter, years, fuels)
    ns = 'auc'
    doc = create_xml_file_object(xml_file)
    measured_scenario_element = nil
    scenario_elements = doc.elements["/#{ns}:BuildingSync/#{ns}:Facilities/#{ns}:Facility/#{ns}:Reports/#{ns}:Report/#{ns}:Scenarios"]
    scenario_elements.each_element do |scenario_element|
      begin
        measured_scenario_element = scenario_element if scenario_element.attributes['ID'] == 'Measured'
      rescue
        puts "scenario issue found in #{xml_file} in scenario: #{scenario_element}"
        puts "scenario_elements: #{scenario_elements}"
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
      scenario_elements.add_element(measured_scenario_element)
    end
    ts_elements = []

    def add_interval_reading(name_space, interval, interval_reading_value, start_time, end_time, fuel)
      ns = name_space
      time_series = REXML::Element.new("#{ns}:TimeSeries")
      reading_type = REXML::Element.new("#{ns}:ReadingType")
      reading_type.text = 'Total'
      time_series_reading_quantity = REXML::Element.new("#{ns}:TimeSeriesReadingQuantity")
      time_series_reading_quantity.text = 'Energy'
      start_time_stamp = REXML::Element.new("#{ns}:StartTimestamp")
      start_time_stamp.text = start_time
      end_time_stamp = REXML::Element.new("#{ns}:EndTimestamp")
      end_time_stamp.text = end_time
      interval_frequency = REXML::Element.new("#{ns}:IntervalFrequency")
      interval_frequency.text = interval
      interval_reading = REXML::Element.new("#{ns}:IntervalReading")
      interval_reading.text = interval_reading_value
      resource_use_id = REXML::Element.new("#{ns}:ResourceUseID")
      resource_use_id.add_attribute('IDref', "#{fuel}")
      time_series.add_element(reading_type)
      time_series.add_element(time_series_reading_quantity)
      time_series.add_element(start_time_stamp)
      time_series.add_element(end_time_stamp)
      time_series.add_element(interval_frequency)
      time_series.add_element(interval_reading)
      time_series.add_element(resource_use_id)
      time_series
    end

    fuels.each do |fuel|
      years.each do |year|
        file_native_value = []
        file_total_value = []
        file_peak_value_array = []
        csv_month_class_collection.each do |single_csv_class|
          if single_csv_class.year == year && single_csv_class.fuel == fuel
            if interval.downcase == 'month'
              ts_elements.push(add_interval_reading(ns, interval, single_csv_class.total_native_value[counter], 
                single_csv_class.start_time_stamp, single_csv_class.end_time_stamp, fuel))
            elsif interval.downcase == 'hour'
              start_time_hourly = []
              end_time_hourly = []
              single_csv_class.start_time_stamp.drop(1).each do |time|
                time.each do |start|
                  start_time_hourly.push start
                  end_time_hourly.push ((start.split(' ')[0]) + ' ' + (start.split(' ')[1].to_i+1).to_s+":00:00")
                end
              end
              single_csv_class.hourly_values[counter].each_with_index do |hourly_value, i|
                ts_elements.push(add_interval_reading(ns, interval, hourly_value, start_time_hourly[i], end_time_hourly[i], fuel))
              end
            end
            file_native_value.push(single_csv_class.total_native_value[counter])
            file_total_value.push(single_csv_class.total_value[counter])
            file_peak_value_array.push(single_csv_class.peak_value_array[counter]) if interval == 'Hour'
          end
        end
        calculate_annual_value(file_native_value, file_total_value, file_peak_value_array, measured_scenario_element, year, fuel)
      end
    end

    time_series_data = REXML::Element.new("#{ns}:TimeSeriesData")
    measured_scenario_element.add_element(time_series_data)
    ts_elements.each do |ts|
      time_series_data.add_element(ts)
    end
    save_xml(xml_file.gsub("#{GENERATE_DIR}", "#{MEASURED_DATA_DIR}"), doc)
  end

  def calculate_annual_value(file_native_value, file_total_value, file_peak_value_array, scenario_element, year, fuel)
    ns = 'auc'
    annual_native_total = file_native_value.inject(0, :+)
    annual_total = file_total_value.inject(0, :+)
    annual_peak_value = file_peak_value_array.max

    resource_uses = REXML::Element.new("#{ns}:ResourceUses")
    resource_use = REXML::Element.new("#{ns}:ResourceUse")
    resource_use.add_attribute('IDref', "#{fuel}")
    energy_resource = REXML::Element.new("#{ns}:EnergyResource")
    energy_resource.text = fuel
    resource_units = REXML::Element.new("#{ns}:ResourceUnits")
    resource_units.text = 'kBtu'
    annual_fuel_use_native_units = REXML::Element.new("#{ns}:AnnualFuelUseNativeUnits")
    annual_fuel_use_native_units.text = annual_native_total
    annual_fuel_use_consistent_units = REXML::Element.new("#{ns}:AnnualFuelUseConsistentUnits")
    annual_fuel_use_consistent_units.text = annual_total

    # Peak vaule for hourly and monthly data
    peak_resource_units = REXML::Element.new("#{ns}:PeakResourceUnits")
    peak_resource_units.text = 'kW'
    annual_peak_native_units = REXML::Element.new("#{ns}:AnnualPeakNativeUnits")
    annual_peak_native_units.text = annual_peak_value
    annual_peak_consistent_units = REXML::Element.new("#{ns}:AnnualPeakConsistentUnits")
    annual_peak_consistent_units.text = annual_peak_value

    scenario_element.add_element(resource_uses)
    resource_uses.add_element(resource_use)
    resource_use.add_element(energy_resource)
    resource_use.add_element(resource_units)
    resource_use.add_element(annual_fuel_use_native_units)
    resource_use.add_element(annual_fuel_use_consistent_units)
    resource_use.add_element(peak_resource_units)
    resource_use.add_element(annual_peak_native_units)
    resource_use.add_element(annual_peak_consistent_units)

    # Add user_defined_field for multi-year and multi-fuel annual total
    user_defined_fields = REXML::Element.new("#{ns}:UserDefinedFields")
    user_defined_field = REXML::Element.new("#{ns}:UserDefinedField")
    field_name = REXML::Element.new("#{ns}:FieldName")
    field_name.text = 'year'
    field_value = REXML::Element.new("#{ns}:FieldValue")
    field_value.text = year
    user_defined_field.add_element(field_name)
    user_defined_field.add_element(field_value)
    user_defined_fields.add_element(user_defined_field)
    resource_uses.add_element(user_defined_fields)

    annual_total
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

  def create_monthly_csv_data(csv_row_collection, interval, fuel_type)
    monthly_csv_obj = MonthlyData.new
    datetime = DateTime.parse(csv_row_collection[0][0])
    # datetime = DateTime.strptime(csv_row_collection[0][0], "%m/%d/%Y")

    monthly_csv_obj.update_month(datetime.month)
    monthly_csv_obj.update_year(datetime.year)
    monthly_csv_obj.update_fuel(fuel_type)

    if interval.downcase == 'hour'
      csv_row_collection.each do |time|
        monthly_csv_obj.update_day(DateTime.parse(csv_row_collection[0][0]).day)
        # monthly_csv_obj.update_day(DateTime.strptime(time[0], "%m/%d/%Y %H:%M").day)
        monthly_csv_obj.update_start_time_hourly(time[0])
      end
      monthly_csv_obj.get_hourly_start_timestamp
    elsif interval.downcase == 'month'
      monthly_csv_obj.update_start_time(csv_row_collection[0][0])
      monthly_csv_obj.update_end_time(csv_row_collection.last[0])
    end

    csv_row_collection.each do |single_row|
      counter = 0
      single_row.headers.each do |header|
        next if header == 'timestamp' || header == 'fuel_type' || header.nil?
        monthly_csv_obj.update_hourly_values(single_row[header], counter) if interval.downcase == 'hour'
        monthly_csv_obj.update_total_values(single_row[header], counter)
        counter += 1
      end
    end

    if interval.downcase == 'hour'
      monthly_csv_obj.get_hourly_values
      (0...monthly_csv_obj.hourly_values.length).each do |i|
        monthly_csv_obj.update_peak_values(monthly_csv_obj.hourly_values[i].max, i)
      end
    end
    monthly_csv_obj.get_peak_value_array
    monthly_csv_obj.get_native_total_values
    monthly_csv_obj.get_total_values

    monthly_csv_obj
  end

  def initiate_measure_data_calculation(csv_file_path, xml_file_path)
    csv_row_collection = []
    csv_month_class_collection = []

    csv_table = CSV.read(csv_file_path, :headers => true)
    header_name = csv_table.headers
    csv_month_value = 0
    months = []
    years = []
    fuels = []
    interval = ''
    fuel_type = ''

    csv_table.each do |csv_row|
      datetime = DateTime.parse(csv_row["timestamp"])
      if datetime.hour.nil?
        interval = 'Month'
      else
        interval = 'Hour'
      end
      years.push(datetime.year)
      months.push(datetime.month)
      if csv_row['fuel_type'].nil?
        csv_row['fuel_type'] = "electricity"
      end
      fuels.push(csv_row['fuel_type'])
    end

    fuels.uniq.each do |fuel|
      years.uniq.each do |year|
        months.uniq.each do |month|
          csv_table.each do |row|
            f = row['fuel_type']
            y = DateTime.parse(row["timestamp"]).year
            m = DateTime.parse(row["timestamp"]).month
            if y == year && m == month && f == fuel
              fuel_type = f
              csv_row_collection.push(row)
            end
          end
          csv_month_class_collection.push(create_monthly_csv_data(csv_row_collection, interval, fuel_type))
          csv_row_collection.clear
        end
      end
    end

    counter = 0
    completed_files = 0
    header_name.drop(1).each do |file_name|
      next if file_name.nil? || file_name == 'fuel_type'
      xml_file = File.expand_path("#{file_name}.xml", xml_file_path.to_s)
      if File.exist?(xml_file)
        add_measured_data_to_xml_file(xml_file, interval, csv_month_class_collection, counter, years.uniq, fuels.uniq)
        completed_files += 1
      else
        puts "No #{file_name} found!"
      end
      counter += 1
    end
    puts "Successfully processed #{completed_files} of #{counter} possible files"
  end
end
