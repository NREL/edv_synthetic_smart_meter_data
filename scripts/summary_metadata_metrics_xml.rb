# return value of element
def value_index(file, list, startline, endline)
  tag = Hash.new

  # find value for outputs within specific line numbers
  (startline..endline).each {|linenum|
    (0...list.size).each { |i|
      if File.readlines(file)[linenum-1].include?list[i]  
	    strings = File.readlines(file)[linenum-1].split(list[i]).last
	    #puts strings
	    strings = strings.split(list[i].insert 1, "/").first
	    #puts strings
        tag[list[i]] = strings
	  end
	}
  }

  return tag
end

# return line index of element
def line_index(file, list)
  tag = Hash.new

  # find line number for outputs in the list 
  File.foreach(file).with_index(1) do |line, index|
    (0...list.size).each { |i|
      if line.include?list[i]
        tag[list[i]] = index
      end
    }
  end
  return tag
end

# extract from a generated bs file:
def summary_existing_xmls()

  #path to xml files
  dir_xml = 'C:/Users/JKIM4/Work/4 EDV/Samples' #TODO: change path to be more generic later on
  
  #run for each xml file line by line
  if(File.exist?(dir_xml))
    puts "######################################################"
    Dir.glob(File.join(dir_xml, "*.xml")).each do |file|
	  puts file
	  puts "######################################################"


	  #########################################################
      # find line numbers of metadata
	  #########################################################
      list_site = ["<auc:IdentifierValue>",\
	  "<auc:YearOfConstruction>",\
	  "<auc:OccupancyClassification>",\
	  "<auc:FloorsAboveGrade>",\
	  "<auc:FloorAreaValue>",\
	  "<auc:State>",\
	  "<auc:PostalCode>",\
	  "<auc:Latitude>",\
	  "<auc:Longitude>"]
	  #########################################################
      # find line numbers of metrics
	  # TODO: need to differentiate measured and modeled metrics
	  #########################################################
	  list_metric = ["<auc:SiteEnergyUseIntensity>",\
	  "<auc:CVRMSE>",\
	  "<auc:NMBE>",\
	  "<auc:CVRMSE>",\
	  "<auc:NMBE>"]
	  #########################################################
	  
	  
	  #########################################################
	  #find line numbers within necessary field
	  #########################################################
	  index_list_site = line_index(file, ["<auc:Site>","</auc:Site>"])
	  #puts index_list_site
	  index_list_metric = line_index(file, ['<auc:Scenario ID="Baseline">'])
	  #puts index_list_metric
	  #########################################################
	  
	  
	  #########################################################
	  #parse value for each parameter
	  #########################################################
      value_list_site = value_index(file, list_site, index_list_site["<auc:Site>"], index_list_site["</auc:Site>"])
	  value_list_metric = value_index(file, list_metric, index_list_metric['<auc:Scenario ID="Baseline">'], index_list_metric['<auc:Scenario ID="Baseline">']+280) #TODO: double check assuming 280 lines is reasonable
	  #########################################################
	  	  
		  
	  #########################################################
	  #assign values to each output parameter
	  #########################################################
	  buildingid = value_list_site["<auc:IdentifierValue>".insert 1, "/"]
	  yearbuilt = value_list_site["<auc:YearOfConstruction>".insert 1, "/"]
	  buildingtype = value_list_site["<auc:OccupancyClassification>".insert 1, "/"]
	  numberofstories = value_list_site["<auc:FloorsAboveGrade>".insert 1, "/"]
	  squarefootage = value_list_site["<auc:FloorAreaValue>".insert 1, "/"]
	  country = value_list_site["<auc:State>".insert 1, "/"]
	  zipcode = value_list_site["<auc:PostalCode>".insert 1, "/"]
	  latitude = value_list_site["<auc:Latitude>".insert 1, "/"]
	  longitude = value_list_site["<auc:Longitude>".insert 1, "/"]
	  actualeui = value_list_metric["<auc:SiteEnergyUseIntensity>".insert 1, "/"]
	  modeleui = value_list_metric["<auc:SiteEnergyUseIntensity>".insert 1, "/"]
	  cvrmseelec = value_list_metric["<auc:CVRMSE>".insert 1, "/"]
	  cvrmsegas = value_list_metric["<auc:NMBE>".insert 1, "/"]
	  nmbeelec = value_list_metric["<auc:CVRMSE>".insert 1, "/"]
	  nmbegas = value_list_metric["<auc:NMBE>".insert 1, "/"]
	  #########################################################
	  
	  puts "Building ID = #{buildingid}"
	  puts "Year built = #{yearbuilt}"
	  puts "Building type = #{buildingtype}"
	  puts "Number of stories = #{numberofstories}"
	  puts "Square footage = #{squarefootage}"
	  puts "US State / Country = #{country}"
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
	  
	  #TODO: create array for including all outputs above. e.g., each row will include all outputs which represents characteristics of one building
	  #TODO: create csv file that contains the array.


    end
  end
end

summary_existing_xmls()