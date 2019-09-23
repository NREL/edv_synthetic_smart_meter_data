# return value of element
def value_index(file, list)
  tag = Hash.new

  # find value for output
  File.foreach(file).with_index(1) do |line, index|
    (0...list.size).each { |i|
      if line.include?list[i]
	    strings = line.split(list[i]).last
		#puts strings
		strings = strings.split(list[i].insert 1, "/").first
		#puts strings
        tag[list[i]] = strings
      end
    }
  end
  return tag
end

# extract from a generated bs file:
def summary_existing_xmls()

  #path to xml files
  dir_xml = 'C:/Users/JKIM4/Work/4 EDV/Samples'
  
  #path to bdgp_with_climatezones_epw_ddy.csv (includes latitude, longitude, city, state zip code)
  dir_meta = 'C:/Users/JKIM4/Documents/GitHub/edv-experiment-1-files/bdgp_with_climatezones_epw_ddy.csv'
  
  #run for each xml file line by line
  if(File.exist?(dir_xml))
    puts "######################################################"
    Dir.glob(File.join(dir_xml, "*.xml")).each do |file|
	  puts file
	  puts "######################################################"

	  #########################################################
      # find line number of specified outputs
	  # TODO: need to add country, zip code, lat, lon, actual EUI, modeled EUI, CVRMSE monthly electricity, CVRMSE monthly gas, NMBE monthly electricity, NMBE monthly gas
	  #########################################################
      list = ["<auc:IdentifierValue>",\
	  "<auc:YearOfConstruction>",\
	  "<auc:OccupancyClassification>",\
	  "<auc:FloorsAboveGrade>",\
	  "<auc:FloorAreaValue>"]
	  #########################################################
	  
	  #parse value for each parameter
      index_list = value_index(file, list)
	  
	  #########################################################
	  buildingid = index_list["<auc:IdentifierValue>".insert 1, "/"]
	  yearbuilt = index_list["<auc:YearOfConstruction>".insert 1, "/"]
	  buildingtype = index_list["<auc:OccupancyClassification>".insert 1, "/"]
	  numberofstories = index_list["<auc:FloorsAboveGrade>".insert 1, "/"]
	  squarefootage = index_list["<auc:FloorAreaValue>".insert 1, "/"]
	  country = ""
	  zipcode = ""
	  latitude = ""
	  longitude = ""
	  actualeui = ""
	  modeleui = ""
	  cvrmseelec = ""
	  cvrmsegas = ""
	  nmbeelec = ""
	  nmbegas = ""
	  #########################################################
	  
	  puts "Building ID = #{buildingid}"
	  puts "Year built = #{yearbuilt}"
	  puts "Building type = #{buildingtype}"
	  puts "Number of stories = #{numberofstories}"
	  puts "Square footage = #{squarefootage}"
	  puts "Country = #{country}"
	  puts "Zip code = #{zipcode}"
	  puts "Latitude = #{latitude}"
	  puts "Longitude = #{longitude}"
	  puts "Actual annual EUI = #{actualeui}"
	  puts "Modeled annual EUI = #{modeleui}"
	  puts "CV(RMSE) monthly electricity = #{cvrmseelec}"
	  puts "CV(RMSE) monthly gas = #{cvrmsegas}"
	  puts "NMBE monthly electricity = #{nmbeelec}"
	  puts "NMBE monthly gas = #{nmbegas}"
	  puts "######################################################"


    end
  end
end

summary_existing_xmls()