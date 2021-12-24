
class Metrics

  def self.calculate_eui_value(annual_energy_consumption, floor_area)
    return annual_energy_consumption / floor_area
  end

  def self.add_eui(resource_element, eui, ns)
    begin
      electricity_resource_use_element = nil?
      if resource_element.elements["#{ns}:EnergyResource"].nil?
        resource_element.elements["#{ns}:ResourceUses"].each do |resource|
          if resource.class == REXML::Element
            electricity_resource_use_element = resource if resource.elements["#{ns}:EnergyResource"].text == "Electricity"
          end
        end
      elsif resource_element.elements["#{ns}:EnergyResource"].text == "Electricity"
        electricity_resource_use_element = resource_element
      end
      if electricity_resource_use_element.nil?
        electricity_resource_use_element = REXML::Element.new("#{ns}:EnergyResource")
        electricity_resource_use_element.Text = "Electricity"
        resource_uses.add_element(electricity_resource_use_element)
      end

      site_energy_use_intensity = REXML::Element.new("#{ns}:SiteEnergyUseIntensity")
      site_energy_use_intensity.text = eui
      electricity_resource_use_element.add_element(site_energy_use_intensity)
      return 1 if !eui.nil?
    rescue
      return 0
    end
  end

  def self.calculate_cvrmse(measured_data_series, simulated_data_series)
    ysum = 0
    squared_error = 0
    sum_error = 0
    match_counter = 0
    measured_values = measured_data_series.get_total_values
    simulated_values = simulated_data_series.get_total_values
    measured_values.each do |index, measured_value|
      next unless measured_value > 0
      simulated_value = simulated_values[index]
      next unless !simulated_value.nil?
      next unless simulated_value > 0
      ysum += measured_value
      squared_error += (measured_value - simulated_value)**2
      sum_error += (measured_value - simulated_value)
      match_counter += 1
    end

    if match_counter > 1
      ybar = ysum / match_counter
      return 100 * ((squared_error / (match_counter - 1))**0.5) / ybar
    end
  end

  def self.calculate_nmbe(measured_data_series, simulated_data_series)
    ysum = 0
    squared_error = 0
    sum_error = 0
    match_counter = 0
    measured_values = measured_data_series.get_total_values
    simulated_values = simulated_data_series.get_total_values
    measured_values.each do |index, measured_value|
      next unless measured_value > 0
      simulated_value = simulated_values[index]
      next unless !simulated_value.nil?
      next unless simulated_value > 0
      ysum += measured_value
      squared_error += (measured_value - simulated_value)**2
      sum_error += (measured_value - simulated_value)
      match_counter += 1
    end

    if match_counter > 1
      ybar = ysum / match_counter
      return 100.0 * (sum_error / (match_counter - 1)) / ybar
    end
  end

  def self.add_user_defined_field(scenario_element, name_of_field, value, ns)
    begin
      electricity_resource_use_element = nil
      resource_uses = scenario_element.elements["#{ns}:ResourceUses"]
      resource_uses.each_element do |resource_use_element|
        if !resource_use_element.elements["#{ns}:EnergyResource"].nil?
          if resource_use_element.elements["#{ns}:EnergyResource"].first == "Electricity"
            electricity_resource_use_element = resource_use_element
          end
        end
      end
      if electricity_resource_use_element.nil?
        electricity_resource_use_element = REXML::Element.new("#{ns}:EnergyResource")
        electricity_resource_use_element.Text = "Electricity"
        resource_uses.add_element(electricity_resource_use_element)
      end

      if electricity_resource_use_element.elements["#{ns}:UserDefinedFields/#{ns}:UserDefinedField/#{ns}:#{name_of_field}"].nil?
        user_defined_fields = nil
        if electricity_resource_use_element.elements["#{ns}:UserDefinedFields"].nil?
          user_defined_fields = REXML::Element.new("#{ns}:UserDefinedFields")
          electricity_resource_use_element.add_element(user_defined_fields)
        else
          user_defined_fields = electricity_resource_use_element.elements["#{ns}:UserDefinedFields"]
        end
        user_defined_field = REXML::Element.new("#{ns}:UserDefinedField")
        nmbe = REXML::Element.new("#{ns}:#{name_of_field}")
        nmbe.text = value
        user_defined_fields.add_element(user_defined_field)
        user_defined_field.add_element(nmbe)
      else
        electricity_resource_use_element.elements["#{ns}:UserDefinedFields/#{ns}:UserDefinedField/#{ns}:#{name_of_field}"].text = value
      end
      return 1 if !value.nil?
    rescue
      return 0
    end
  end

end
