class StdInput

  def include_headers(new_file, std_labels)
    return new_file.puts std_labels
  end

  def copy_columns(file, options)
    unless File.exists?(File.basename(file, '.csv') + '_standardized.csv')
      CSV.open((File.basename(file, '.csv') + '_standardized.csv'), 'a+') do |csv|
        csv << ['building_id',
                'xml_filename',
                'primary_building_type',
                'floor_area_sqft',
                'vintage',
                'climate_zone',
                'zipcode',
                'city',
                'us_state',
                'longitude',
                'latitude',
                'number_of_stories',
                'number_of_occupants',
                'fuel_type_heating',
                'energystar_score',
                'measurement_start_date',
                'measurement_end_date',
                'weather_file_name_epw',
                'weather_file_name_ddy'] if csv.count.eql?0
      end

      CSV.foreach(file, options) do |feature|

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

        File.open((File.basename(file, '.csv') + '_standardized.csv'), 'a+').puts "#{building_id},#{building_id}.xml,#{primary_building_type},#{floor_area_sqft},#{vintage},#{climate_zone},#{zipcode},#{city},#{us_state},#{longitude},#{latitude},#{number_of_stories},#{number_of_occupants},#{fuel_type_heating},#{energystar_score},#{measurement_start_date},#{measurement_end_date},#{weather_file_name_epw},#{weather_file_name_ddy}"
      end
      return (File.basename(file, '.csv') + '_standardized.csv').to_s
    end
  end
end
