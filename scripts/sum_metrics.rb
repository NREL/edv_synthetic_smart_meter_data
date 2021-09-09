require 'rexml/document'
require 'csv'
require 'fileutils'
require_relative 'constants'

include REXML

xml_dir = File.join(File.dirname(__FILE__), '..', "#{WORKFLOW_OUTPUT_DIR}/#{CALC_METRICS_DIR}")
csv_dir = File.join(File.dirname(__FILE__), '..', "#{WORKFLOW_OUTPUT_DIR}/results")


if !File.exists?(xml_dir)
  puts "Does not exist: " + xml_dir
  puts "Buildingsync xml files should be stored in edv-experiment-1/Test_output/Simulation_Files"
  exit(1)
end

xml_dir = File.realpath(xml_dir)

if !File.exists?(csv_dir)
  FileUtils.mkdir_p(csv_dir)
  csv_dir = File.realpath(csv_dir)
  puts 'Creating: ' + csv_dir.to_s
end

csv_dir = File.realpath(csv_dir)

def create_building_dict(file)
  b_dict = {}
  doc = File.open(file) { |f| Document.new(f) }
  site_string = '//auc:Site[1]'
  building_string = site_string + '/auc:Buildings/auc:Building[1]'
  scenarios_string = '//auc:Reports/auc:Report[1]/auc:Scenarios'
  elec_metrics_string = scenarios_string + "/auc:Scenario[@ID='Baseline']//auc:ResourceUse[@ID='Baseline_Electricity']"

  b_id = XPath.first(doc, building_string + '/@ID').to_s
  year = XPath.first(doc, building_string + '/auc:YearOfConstruction/text()').to_s
  occ = XPath.first(doc, building_string + '/auc:OccupancyClassification/text()').to_s
  num_stories = XPath.first(doc, building_string + '/auc:FloorsAboveGrade/text()').to_s
  area = XPath.first(doc, building_string + "/auc:FloorAreas/auc:FloorArea[auc:FloorAreaType='Gross']/auc:FloorAreaValue/text()").to_s
  state = XPath.first(doc, site_string + '/auc:Address/auc:State/text()').to_s
  zip = XPath.first(doc, site_string + '/auc:Address//auc:PostalCode/text()').to_s
  lat = XPath.first(doc, site_string + '/auc:Latitude/text()').to_s
  long = XPath.first(doc, site_string + '/auc:Longitude/text()').to_s
  cons_model = XPath.first(doc, scenarios_string + "/auc:Scenario[@ID='Baseline']//auc:ResourceUse[@ID='Baseline_Electricity']" +
      "/auc:AnnualFuelUseNativeUnits/text()").to_s
  cons_act = XPath.first(doc, scenarios_string + "/auc:Scenario[@ID='Measured']//auc:ResourceUse[auc:EnergyResource='Electricity']" +
      "/auc:AnnualFuelUseNativeUnits/text() ").to_s

  cvrm_elec = XPath.first(doc, elec_metrics_string +  "//auc:CVRMSE/text()").to_s
  nmbe_elec = XPath.first(doc, elec_metrics_string +  "//auc:NMBE/text()").to_s

  b_dict["buildingid"] = b_id
  b_dict["yearbuilt"] = year
  b_dict["buildingtype"] = occ
  b_dict["numberofstories"] = num_stories
  b_dict["squarefootage"] = area
  b_dict["state"] = state
  b_dict["zipcode"] = zip
  b_dict["latitude"] = lat
  b_dict["longitude"] = long
  b_dict["consumption_actual"] = cons_act
  b_dict["consumption_model"] = cons_model
  b_dict["cvrmseelec"] = cvrm_elec
  b_dict["nmbeelec"] = nmbe_elec
  return b_dict
end

def write_file(list_dict, csv_dir)
  f = File.join(csv_dir, 'results.csv')
  CSV.open(f, "w", headers: list_dict.first.keys, write_headers: true) do |csv|
    list_dict.each do |h|
      csv << h.values
    end
  end
end

def create_building_dicts(xml_dir, csv_dir)
  results = []

  files = Dir[xml_dir + '/**/*.xml']

  if files.size == 0
    puts "No XML files in directory: " + xml_dir
    exit(1)
  end

  files.each do |f|
    result = create_building_dict(f)
    results << result
  end

  write_file(results, csv_dir)

end

###############################################
# To use for testing purposes
# f = File.join(xml_dir, 'Office_Gisselle.xml')
# create_building_dict(f)
###############################################

create_building_dicts(xml_dir, csv_dir)