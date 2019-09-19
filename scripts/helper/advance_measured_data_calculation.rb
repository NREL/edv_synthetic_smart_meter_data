require_relative 'csv_monthly_data'

require 'csv'
require 'date'
require 'rexml/document'

class AdvanceMeasuredDataCalculation
  @doc = nil
  @unit_converted_value = nil
  @ns = nil

  def initialize(doc, unit_converted_value, ns)
    @doc = doc
    @unit_converted_value = unit_converted_value
    @ns = ns
  end

  def get_floor_area_value
    measured_floor_element = nil
    floor_areas = @doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Sites/#{@ns}:Site/#{@ns}:Buildings/#{@ns}:Building/#{@ns}:FloorAreas"]
    floor_areas.each do |floor_element|
      if floor_element.elements["#{@ns}:FloorAreaType"].text == 'Gross'
        measured_floor_element = floor_element
      end
    end

    measured_floor_element.elements["#{@ns}:FloorAreaValue"].text
  end

  def calculate_actual_eui_value(floor_area)
    p "unit converted value :- #{@unit_converted_value}"
    p "floor value :- #{floor_area}"
    return @unit_converted_value.to_f / floor_area.to_f if floor_area.to_f > 0
  end

  def calculate_modeled_eui_value
    floor_area = get_floor_area_value
    scenario_elements = @doc.elements["#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Reports/#{@ns}:Report/#{@ns}:Scenarios"]
    scenario_elements.each do |scenario_element|
      next unless scenario_element.attributes['ID'] == 'Measured'
      scenario_element.elements["#{@ns}:ResourceUses"].each do |resource_use_element|
        annual_fuel_use_consistent_units = resource_use_element.elements["#{@ns}:AnnualFuelUseConsistentUnits"].text

        site_energy_use_intensity = REXML::Element.new("#{@ns}:SiteEnergyUseIntensity")
        actual_aui = REXML::Element.new("#{@ns}:ActualEUI")
        actual_aui.text = calculate_actual_eui_value(floor_area)
        modeled_aui = REXML::Element.new("#{@ns}:ModeledEUI")
        modeled_aui.text = annual_fuel_use_consistent_units.to_f / floor_area.to_f

        resource_use_element.add_element(site_energy_use_intensity)
        site_energy_use_intensity.add_element(actual_aui)
        site_energy_use_intensity.add_element(modeled_aui)
      end
    end
  end

  def cvrmse_nmbe_calculation(csv_month_class_collection, counter)
    scenario_elements = @doc.elements["#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Reports/#{@ns}:Report/#{@ns}:Scenarios"]
    scenario_elements.each do |scenario_element|
      next unless scenario_element.attributes['ID'] != 'Measured'
      monthly_billing_period_calculation(scenario_element, csv_month_class_collection, counter)
    end
  end

  def monthly_billing_period_calculation(scenario_element, csv_month_class_collection, counter)
    ysum = 0
    squared_error = 0
    sum_error = 0
    match_counter = 0

    csv_month_class_collection.each do |single_csv_class|
      measured_value = single_csv_class.get_values[counter]
      next unless measured_value > 0
      measured_date = single_csv_class.start_time_stamp.to_date
      simulated_value = find_same_date_simulation_data(scenario_element, measured_date)
      next unless simulated_value > 0
      ysum += single_csv_class.get_values[counter]
      squared_error += (measured_value - simulated_value)**2
      sum_error += (measured_value - simulated_value)
      match_counter += 1
    end

    if match_counter > 1
      ybar = ysum / match_counter
      cvrmse_result = 100 * ((squared_error / (match_counter - 1))**0.5) / ybar
      nmbe_result = 100.0 * (sum_error / (match_counter - 1)) / ybar
      add_cvrmse_and_nmbe_into_xml(scenario_element, cvrmse_result, nmbe_result)
    end
  end

  def find_same_date_simulation_data(scenario_element, measured_date)
    scenario_element.elements["#{@ns}:TimeSeriesData"].each do |time_series|
      simulated_date = time_series.elements["#{@ns}:StartTimeStamp"].text
      interval_reading = time_series.elements["#{@ns}:IntervalReading"].text
      next unless !interval_reading.nil? && interval_reading > 0
      return interval_reading if simulated_date.to_date == measured_date
    end
    0
  end

  def add_cvrmse_and_nmbe_into_xml(scenario_element, cvrmse_result, nmbe_result)
    resource_use_element = scenario_element.elements["#{@ns}:ResourceUses/#{@ns}:ResourceUse"]

    user_defined_fields = REXML::Element.new("#{@ns}:UserDefinedFields")
    user_defined_field = REXML::Element.new("#{@ns}:UserDefinedField")
    cvrmse = REXML::Element.new("#{@ns}:CVRMSE")
    cvrmse.text = cvrmse_result
    nmbe = REXML::Element.new("#{@ns}:NMBE")
    nmbe.text = nmbe_result

    resource_use_element.add_element(user_defined_fields)
    user_defined_fields.add_element(user_defined_field)
    user_defined_field.add_element(cvrmse)
    user_defined_field.add_element(nmbe)
  end
end
