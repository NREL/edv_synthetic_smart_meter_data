require 'json'

# return value of element
def value_index(file, list, startline, endline)
  tag = Hash.new
  
  # find value for outputs within specific line numbers
  (startline..endline).each {|linenum|
    (0...list.size).each { |i|
      if File.readlines(file)[linenum-1].include?list[i]  
	    startstring = File.readlines(file)[linenum-1].split(list[i]).last
		endstring = "</"+list[i][1..-1]
	    value = startstring.split(endstring).first
        tag[list[i]] = value
	  end
	}
  }

  return tag
end



def line_index(file, list, startline, endline)
  tag = Hash.new
  
  # find line number for outputs in the list 
  (startline..endline).each {|linenum|
    (0...list.size).each { |i|
      if File.readlines(file)[linenum-1].include?list[i]
        tag[list[i]] = linenum
      end
    }
  }
  return tag
end



# extract from a generated bs file:
def summary_existing_xmls()

  #path to xml files
  dir_xml = 'C:/Users/kimja/Documents/GitHub/test' #TODO: change path to be more generic later on
  
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
	  "<auc:SiteEnergyUse>",\
	  "<auc:AnnualFuelUseNativeUnits>"]
	  #########################################################
	  
	  
	  #########################################################
	  #find line numbers within necessary field
	  #########################################################
	  total_line_numbers = File.readlines(file).size
	  index_list_site = line_index(file, ['<auc:Site>','<auc:YearOfConstruction>'],1,total_line_numbers)
	  #puts index_list_site
	  index_list_baseline_model = line_index(file, ['<auc:ResourceUse ID="Baseline_Electricity">'],1,total_line_numbers)
	  #puts index_list_baseline_model
	  index_list_baseline_actual = line_index(file, ['<auc:ResourceUse>','</auc:ResourceUse>'],1,total_line_numbers)
	  #puts index_list_baseline_actual
	  #########################################################
	  
	  
	  #########################################################
	  #parse value for each parameter #TODO: need more efficient/generic field grabbing
	  #########################################################
      list_site = value_index(file, list_site, index_list_site['<auc:Site>'], index_list_site['<auc:YearOfConstruction>'])
	  #puts "SITE INFO: #{list_site}"
	  
	  list_baseline_model = value_index(file, list_metric, index_list_baseline_model['<auc:ResourceUse ID="Baseline_Electricity">'], index_list_baseline_model['<auc:ResourceUse ID="Baseline_Electricity">']+7) 
	  #puts "MODEL INFO: #{list_baseline_model}"
	  
	  list_baseline_actual = value_index(file, list_metric, index_list_baseline_actual['<auc:ResourceUse>'], index_list_baseline_actual['</auc:ResourceUse>'])
	  #puts "MEASURED INFO: #{list_baseline_actual}"
	  #########################################################
	  	  
		  
	  #########################################################
	  #assign values to each output parameter
	  #########################################################
	  summary = Hash.new
	  summary['buildingid'] = list_site["<auc:IdentifierValue>"]
	  summary['yearbuilt'] = list_site["<auc:YearOfConstruction>"]
	  summary['buildingtype'] = list_site["<auc:OccupancyClassification>"]
	  summary['numberofstories'] = list_site["<auc:FloorsAboveGrade>"]
	  summary['squarefootage'] = list_site["<auc:FloorAreaValue>"]
	  summary['country'] = list_site["<auc:State>"]
	  summary['zipcode'] = list_site["<auc:PostalCode>"]
	  summary['latitude'] = list_site["<auc:Latitude>"]
	  summary['longitude'] = list_site["<auc:Longitude>"]
	  summary['cvrmseelec'] = list_baseline_model["<auc:CVRMSE>"]
	  summary['cvrmsegas'] = list_baseline_model["<auc:NMBE>"]
	  summary['nmbeelec'] = list_baseline_model["<auc:CVRMSE>"]
	  summary['nmbegas'] = list_baseline_model["<auc:NMBE>"]
	  summary['consumption_actual'] = list_baseline_actual['<auc:AnnualFuelUseNativeUnits>']
	  summary['consumption_model'] = list_baseline_model['<auc:AnnualFuelUseNativeUnits>']
	  #########################################################
	  
	  puts "Building ID = #{summary['buildingid']}"
	  puts "Year built = #{summary['yearbuilt']}"
	  puts "Building type = #{summary['buildingtype']}"
	  puts "Number of stories = #{summary['numberofstories']}"
	  puts "Square footage = #{summary['squarefootage'].to_f.round} sqft"
	  puts "US State / Country = #{summary['country']}"
	  puts "Zip code = #{summary['zipcode']}"
	  puts "Latitude = #{summary['latitude']}"
	  puts "Longitude = #{summary['longitude']}"
	  puts "Annual electricity consumption (actual) = #{summary['consumption_actual'].to_f.round} kBtu/yr"
	  puts "Annual electricity consumption (model)  = #{summary['consumption_model'].to_f.round} kBtu/yr"
	  puts "CV(RMSE) monthly electricity = #{summary['cvrmseelec']}"
	  puts "CV(RMSE) monthly gas = #{summary['cvrmsegas']}"
	  puts "NMBE monthly electricity = #{summary['nmbeelec']}"
	  puts "NMBE monthly gas = #{summary['nmbegas']}"
	  puts "######################################################"
	  
      summary_json = summary.to_json
	  
	  #puts "HASH: #{summary}"
	  #puts "JSON: #{summary_json}"
	  
      File.open("summary.json","ab"){ |f| f.write summary_json }

    end
  end
end

summary_existing_xmls()