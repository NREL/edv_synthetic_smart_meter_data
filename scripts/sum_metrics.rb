require 'nokogiri'
require 'csv'

xml_dir = File.join(File.dirname(__FILE__), '..', 'Test_output/Simulation_Files')
csv_dir = File.join(File.dirname(__FILE__), '..', 'Test_output/results')


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
  doc = File.open(file) { |f| Nokogiri::XML(f) }

  site_string = '//auc:Site[1]'
  building_string = site_string + '/auc:Buildings/auc:Building[1]'
  scenarios_string = '//auc:Reports/auc:Report[1]/auc:Scenarios'

  b_id = doc.xpath(building_string + '/@ID').to_s
  year = doc.xpath(building_string + '/auc:YearOfConstruction/text()').to_s
  occ = doc.xpath(building_string + '/auc:OccupancyClassification/text()').to_s
  num_stories = doc.xpath(building_string + '/auc:FloorsAboveGrade/text()').to_s
  area = doc.xpath(building_string + "/auc:FloorAreas/auc:FloorArea[auc:FloorAreaType='Gross']/auc:FloorAreaValue/text()").to_s
  state = doc.xpath(site_string + '/auc:Address/auc:State/text()').to_s
  zip = doc.xpath(site_string + '/auc:Address//auc:PostalCode/text()').to_s
  lat = doc.xpath(site_string + '/auc:Latitude/text()').to_s
  long = doc.xpath(site_string + '/auc:Longitude/text()').to_s
  cons_act = doc.xpath(scenarios_string + "/auc:Scenario[@ID='Baseline']//auc:ResourceUse[@ID='Baseline_Electricity']" +
                           "/auc:AnnualFuelUseNativeUnits/text()").to_s
  cons_model = doc.xpath('(' + scenarios_string +
                             "/auc:Scenario[@ID='Measured']//auc:ResourceUse[auc:EnergyResource='Electricity']" + ")[1]" +
                             "/auc:AnnualFuelUseNativeUnits/text()").to_s

  # cvrm_elec = doc.xpath(building_string + '/auc:FloorsAboveGrade/text()').to_s
  # nmbe_elec = doc.xpath(building_string + '/auc:FloorsAboveGrade/text()').to_s
  # puts cons_act
  # puts cons_model

  b_dict["buildingid"] = b_id
  b_dict["yearbuilt"] = year
  b_dict["buildingtype"] = occ
  b_dict["numberofstories"] = num_stories
  b_dict["squarefootage"] = area
  b_dict["state"] = state
  b_dict["zipcode"] = zip
  b_dict["latitude"] = lat
  b_dict["longitude"] = long
  # b_dict["cvrmseelec"] = cvrm_elec
  # b_dict["nmbeelec"] = nmbe_elec
  b_dict["consumption_actual"] = cons_act
  b_dict["consumption_model"] = cons_model

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

  files = Dir[xml_dir + '/*.xml']

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

f = File.join(xml_dir, 'UnivDorm_Christi.xml')

# create_building_dict(f)
create_building_dicts(xml_dir, csv_dir)