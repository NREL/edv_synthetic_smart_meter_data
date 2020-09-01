class StandardizedInput

  def map_location_with_latlng(file, outdir, options = {headers: true, header_converters: :symbol})
    updated_features = []
    # headers = []
    lat_lng_arr = []

    CSV.foreach(file, options) do |row|
      lat_lng_arr << {:building_id => row[:building_id], :lat => row[:lat], :lng => row[:lng]}
    end
    # puts "lat_lng_arr size: #{lat_lng_arr.size}"

    puts "###############################################"
    CSV.foreach(file, options).with_index do |feature, i|
	    puts "Verifying latitude and longitude in location #{i.next} out of #{lat_lng_arr.size} locations"
      # headers = feature.headers

      # geocoder
      res = Geocoder.search("#{feature[:lat]}, #{feature[:lng]}")
      if (feature[:lat].to_s.empty?)||(feature[:lng].to_s.empty?)
        feature[:zipcode] = ""
        puts "zipcode: n/a"
        feature[:city] = ""
        puts "city: n/a"
        feature[:state] = ""
        puts "state: n/a"
      else
        feature[:zipcode] = res.first.postal_code
        puts "zipcode: #{res.first.postal_code}"
        feature[:city] = res.first.city
        puts "city: #{res.first.city}"
        feature[:state] = res.first.state
        puts "state: #{res.first.state}"
      end
      puts "###############################################"
	    updated_features << feature

    end

    # headers << :zipcode
    # headers << :city
    # headers << :state

    # # write new array to file
    # puts "Processed file saved at #{outdir}"
    # CSV.open(outdir + "/metadata.csv", "w+") do |csv|
      # csv << headers
      # updated_features.each do |row|
  	    # csv << row
      # end
    # end

	  updated_features
		
  end

  def copy_columns(file, std_labels, outdir, updated_features, options = {headers: true, header_converters: :symbol})
    metadata_file = File.open(outdir + '/metadata.csv', 'w+')
    puts "#{File.basename(file)}"
	  puts "Adding standard labels (header names) into metadata.csv file"
    metadata_file.puts std_labels
		  
	  puts "Adding values of standard labels into metadata.csv file"
    updated_features.each do |row|
      building_id = row[:building_id]
      primary_building_type = row[:primaryspaceusage]
      floor_area_sqft = row[:sqft]
      vintage = row[:yearbuilt]
      climate_zone = row[:climate_zone]
      weather_file_name_epw = row[:epw]
      weather_file_name_ddy = row[:ddy]
      zipcode = row[:zipcode]
      city = row[:city]
      us_state = row[:state]
      longitude = row[:lng]
      latitude = row[:lat]
      number_of_stories = row[:numberoffloors]
      number_of_occupants = row[:occupants]
      fuel_type = row[:heatingtype]
      energystar_score = row[:energystarscore]
      measurement_start_date = row[:datastart]
      measurement_end_date = row[:dataend]
		
	    metadata_file.puts "#{building_id},#{building_id}.xml,#{primary_building_type},#{floor_area_sqft},#{vintage},#{climate_zone},#{zipcode},#{city},#{us_state},#{longitude},#{latitude},#{number_of_stories},#{number_of_occupants},#{fuel_type},#{energystar_score},#{measurement_start_date},#{measurement_end_date},#{weather_file_name_epw},#{weather_file_name_ddy}"

    end
	  puts "###############################################"
    
  end
  
end

