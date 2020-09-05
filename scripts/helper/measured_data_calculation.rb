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

  def add_measured_data_to_xml_file(xml_file, interval, csv_month_class_collection, counter, years)
    ns = 'auc'
    doc = create_xml_file_object(xml_file)
    measured_scenario_element = nil
    scenario_elements = doc.elements["/#{ns}:BuildingSync/#{ns}:Facilities/#{ns}:Facility/#{ns}:Reports/#{ns}:Report/#{ns}:Scenarios"]
    scenario_elements.each do |scenario_element|
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

    years.each do |year|
      file_native_value = []
      file_total_value = []
      csv_month_class_collection.each do |single_csv_class|
        if single_csv_class.year == year
          if interval.downcase == 'month'
            time_series = REXML::Element.new("#{ns}:TimeSeries")
            reading_type = REXML::Element.new("#{ns}:ReadingType")
            reading_type.text = 'Total'
            time_series_reading_quantity = REXML::Element.new("#{ns}:TimeSeriesReadingQuantity")
            time_series_reading_quantity.text = 'Energy'
            start_time_stamp = REXML::Element.new("#{ns}:StartTimestamp")
            start_time_stamp.text = single_csv_class.start_time_stamp
            end_time_stamp = REXML::Element.new("#{ns}:EndTimestamp")
            end_time_stamp.text = single_csv_class.end_time_stamp
            interval_frequency = REXML::Element.new("#{ns}:IntervalFrequency")
            interval_frequency.text = interval
            interval_reading = REXML::Element.new("#{ns}:IntervalReading")
            interval_reading.text = single_csv_class.annual_native_total[counter]
            time_series.add_element(interval_reading)
            time_series.add_element(reading_type)
            time_series.add_element(time_series_reading_quantity)
            time_series.add_element(start_time_stamp)
            time_series.add_element(end_time_stamp)
            time_series.add_element(interval_frequency)
            time_series.add_element(interval_reading)
            ts_elements.push(time_series)

            file_native_value.push(single_csv_class.annual_native_total[counter])
            file_total_value.push(single_csv_class.annual_total[counter])
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
              time_series = REXML::Element.new("#{ns}:TimeSeries")
              reading_type = REXML::Element.new("#{ns}:ReadingType")
              reading_type.text = 'Total'
              time_series_reading_quantity = REXML::Element.new("#{ns}:TimeSeriesReadingQuantity")
              time_series_reading_quantity.text = 'Energy'
              start_time_stamp = REXML::Element.new("#{ns}:StartTimestamp")
              start_time_stamp.text = start_time_hourly[i]
              end_time_stamp = REXML::Element.new("#{ns}:EndTimestamp")
              end_time_stamp.text = end_time_hourly[i]
              interval_frequency = REXML::Element.new("#{ns}:IntervalFrequency")
              interval_frequency.text = interval
              interval_reading = REXML::Element.new("#{ns}:IntervalReading")
              interval_reading.text = hourly_value
              time_series.add_element(reading_type)
              time_series.add_element(time_series_reading_quantity)
              time_series.add_element(start_time_stamp)
              time_series.add_element(end_time_stamp)
              time_series.add_element(interval_frequency)
              time_series.add_element(interval_reading)
              ts_elements.push(time_series)
            end
            file_native_value.push(single_csv_class.monthly_native_total[counter])
            file_total_value.push(single_csv_class.monthly_total[counter])
          end
        end
      end
      calculate_annual_value(file_native_value, file_total_value, measured_scenario_element, year)
    end
    time_series_data = REXML::Element.new("#{ns}:TimeSeriesData")
    measured_scenario_element.add_element(time_series_data)
    ts_elements.each do |ts|
      time_series_data.add_element(ts)
    end

    save_xml(xml_file.gsub("#{GENERATE_DIR}", "#{ADD_MEASURED_DIR}"), doc)
  end

  def calculate_annual_value(file_native_value, file_total_value, scenario_element, year)
    ns = 'auc'
    annual_native_total = file_native_value.inject(0, :+)
    annual_total = file_total_value.inject(0, :+)
    annual_max_value = file_native_value.max

    resource_uses = REXML::Element.new("#{ns}:ResourceUses")
    resource_use = REXML::Element.new("#{ns}:ResourceUse")
    energy_resource = REXML::Element.new("#{ns}:EnergyResource")
    energy_resource.text = 'Electricity'
    resource_units = REXML::Element.new("#{ns}:ResourceUnits")
    resource_units.text = 'kBtu'
    annual_fuel_use_native_units = REXML::Element.new("#{ns}:AnnualFuelUseNativeUnits")
    annual_fuel_use_native_units.text = annual_native_total
    annual_fuel_use_consistent_units = REXML::Element.new("#{ns}:AnnualFuelUseConsistentUnits")
    annual_fuel_use_consistent_units.text = annual_total
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

    # Add user_defined_field for multi-year annual total
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

  def create_monthly_csv_data(csv_row_collection, interval)
    monthly_csv_obj = MonthlyData.new
    datetime = DateTime.strptime(csv_row_collection[0][0], "%m/%d/%y")
    monthly_csv_obj.update_month(datetime.month)
    monthly_csv_obj.update_year(datetime.year)
    monthly_csv_obj.initialize_native_value
    monthly_csv_obj.initialize_total_value

    if interval.downcase == 'hour'
      csv_row_collection.each do |time|
        monthly_csv_obj.update_day(DateTime.strptime(time[0], "%m/%d/%y %H:%M").day)
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
        next if header == 'timestamp'
        if interval.downcase == 'hour'
          monthly_csv_obj.update_hourly_values(single_row[header], counter)
          monthly_csv_obj.update_monthly_total(single_row[header], counter)
        elsif interval.downcase == 'month'
          monthly_csv_obj.update_total_values(single_row[header], counter)
        end
        counter += 1
      end
    end
    if interval.downcase == 'hour'
      monthly_csv_obj.get_hourly_values
      monthly_csv_obj.get_monthly_native_total
      monthly_csv_obj.get_monthly_total
      # puts "#{monthly_csv_obj.month} monthly native total and total: #{monthly_csv_obj.get_monthly_native_total}, #{monthly_csv_obj.monthly_total}"
    elsif interval.downcase == 'month'
      monthly_csv_obj.get_annual_native_total
      monthly_csv_obj.get_annual_total
    end

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
    interval = ''

    csv_table.each do |csv_row|
      datetime = DateTime.strptime(csv_row["timestamp"], "%m/%d/%y %k:%M")
      if !datetime.hour.nil?
        interval = 'Hour'
      elsif !datetime.month.nil?
        interval = 'Month'
      end
      years.push(datetime.year)
      months.push(datetime.month)
    end

    years.uniq.each do |year|
      months.uniq.each do |month|
        csv_table.each do |row|
          if DateTime.strptime(row["timestamp"], "%m/%d/%y").year == year &&
            DateTime.strptime(row["timestamp"], "%m/%d/%y").month == month
            csv_row_collection.push(row)
          end
        end
        csv_month_class_collection.push(create_monthly_csv_data(csv_row_collection, interval))
        csv_row_collection.clear
      end
    end

    counter = 0
    completed_files = 0
    header_name.drop(1).each do |file_name|
      xml_file = File.expand_path("#{file_name}.xml", xml_file_path.to_s)
      if File.exist?(xml_file)
        add_measured_data_to_xml_file(xml_file, interval, csv_month_class_collection, counter, years.uniq)
        completed_files += 1
      else
        puts "No #{file_name} found!"
      end
      counter += 1
    end
    puts "Successfully processed #{completed_files} of #{counter} possible files"
  end
end
