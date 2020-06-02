
class StdInput

  def self.include_headers(new_file, std_labels)
    return new_file.puts std_labels
  end
  
  
  def self.copy_columns(metadata_file)
  
    CSV.foreach(metadata_file, options) do |feature|
      
      building_id = feature[:uid]
      primary_building_type = feature[:primaryspaceusage]
      floor_area_sqft = feature[:sqft]
      vintage = feature[:yearbuilt]
      climate_zone = feature[:climate_zone]
      weather_file_name_epw = feature[:epw]
      weather_file_name_ddy = feature[:ddy]
      zipcode = feature[:zipcode]
      city = feature[:city]
      us_state = feature[:state]
      longitude = feature[:lng]
      latitude = feature[:lat]
      number_of_stories = feature[:numberoffloors]
      number_of_occupants = feature[:occupants]
      fuel_type_heating = feature[:heatingtype]
      energystar_score = feature[:energystarscore]
      measurement_start_date = feature[:datastart]
      measurement_end_date = feature[:dataend]

      metadata_file.puts "#{building_id},#{building_id}.xml,#{primary_building_type},#{floor_area_sqft},#{vintage},#{climate_zone},#{zipcode},#{city},#{us_state},#{longitude},#{latitude},#{number_of_stories},#{number_of_occupants},#{fuel_type_heating},#{energystar_score},#{measurement_start_date},#{measurement_end_date},#{weather_file_name_epw},#{weather_file_name_ddy}"

    end
  
  end

end
