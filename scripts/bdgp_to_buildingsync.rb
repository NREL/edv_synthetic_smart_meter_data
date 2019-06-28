# convert Building Data Genome Project metadata to BuildingSync XML files

# Notes: Dates are in DD/MM/YYYY format (convert)
# TODO: Map space types
# TODO: Add checks:  what's the minimum data fields we 'require'?

require 'csv'
require 'rexml/document'
require 'FileUtils'

if ARGV[0].nil? || !File.exist?(ARGV[0])
  puts 'usage: bundle exec ruby bdgp_to_buildingsync.rb /path/to/csv'
  puts ".csv files only"
  exit(1)
end

def convert(value, unit_in, unit_out)
  if value.nil?
    raise 'No value to convert'
  end

  if unit_in == unit_out
  elsif unit_in == 'm'
    if unit_out == 'ft'
      value = 3.28084 * value
    end
  elsif unit_in == 'm2'
    if unit_out == 'ft2'
      value = 10.7639 * value
    end
  end
  return value
end

def get_building_id(feature)
  return feature[:uid]
end

def get_floor_area(feature)
  if feature[:sqft].nil?
    raise 'Floor Area (SQFT) is empty'
  end

  return convert(feature[:sqft], 'ft2', 'ft2')
end

def get_year_built(feature)
  # remove "pre" and "post"
  yrblt = feature[:yearbuilt]
  if !yrblt.nil?
    yrblt.gsub('pre ', '')
    yrblt.gsub('Pre ', '')
    yrblt.gsub('post ', '')
    yrblt.gsub('Post ', '')

    # take last number if given a range
    yrs = yrblt.split('-')
    yrblt = yrs[-1]
  end
  if !/\A\d+\z/.match(yrblt)
    return ''
  else
    return yrblt
  end
end

def get_building_classification(feature)
  classification = feature[:primaryspaceusage]

  # possible mappings: Commercial, Residential, Mixed use commercial, Other 
  # from CSV: Office, Primary/Secondary Classroom, College Classroom, Dormitory, College Laboratory

  result = nil
  case classification
  when 'Office'
    result = 'Commercial'      
  when 'Primary/Secondary Classroom'
  	result = 'Commercial'
  when 'College Classroom'
  	result = 'Commercial'
  when 'Dormitory'
  	result = 'Commercial'
  when 'College Laboratory'
  	result = 'Commercial'
  else
    raise "Unknown classification #{classification}"
  end

  return result
end

def get_occupancy_classification(feature)
  classification = feature[:primaryspaceusage]
  # for now, only doing Office, Retail, and Small Hotels
  result = nil
  case classification
  when 'Office'
    result = 'Office'      
  when 'Primary/Secondary Classroom'
  	result = 'Office'
  when 'College Classroom'
  	result = 'Office'
  when 'Dormitory'
  	result = 'Lodging'
  when 'College Laboratory'
  	rsult = 'Office'
  else
    raise "Unknown classification #{classification}"
  end

  return result
end

def create_site(feature)
	site = REXML::Element.new('auc:Site')
  feature_id = get_building_id(feature)
  
  raise "Building ID is empty" if feature_id.nil?

  # ownership
  ownership = REXML::Element.new('auc:Ownership')
  ownership.text = 'Unknown'
  site.add_element(ownership)
  
  # buildings
  buildings = REXML::Element.new('auc:Buildings')
  building = REXML::Element.new('auc:Building')
  building.attributes['ID'] = feature_id

  # default name
  feature[:nickname] = "Building" if feature[:nickname].nil?
  raise "Building Nickname is not set" if feature[:nickname].nil?

  premises_name = REXML::Element.new('auc:PremisesName')
  premises_name.text = "Building #{feature[:nickname]}"
  building.add_element(premises_name)
  
  premises_notes = REXML::Element.new('auc:PremisesNotes')
  premises_notes.text = ''
  building.add_element(premises_notes)

  premises_identifiers = REXML::Element.new('auc:PremisesIdentifiers')
  
  premises_identifier = REXML::Element.new('auc:PremisesIdentifier')
  identifier_label = REXML::Element.new('auc:IdentifierLabel')
  identifier_label.text = 'Custom'
  premises_identifier.add_element(identifier_label)
  identifier_value = REXML::Element.new('auc:IdentifierValue')
  identifier_value.text = feature_id
  premises_identifier.add_element(identifier_value)
  premises_identifiers.add_element(premises_identifier)

  building.add_element(premises_identifiers)

  building_classification = REXML::Element.new('auc:BuildingClassification')
  building_classification.text = get_building_classification(feature)
  building.add_element(building_classification)

  occupancy_classification = REXML::Element.new('auc:OccupancyClassification')
  occupancy_classification.text = get_occupancy_classification(feature)
  building.add_element(occupancy_classification)

  floors_above_grade = REXML::Element.new('auc:FloorsAboveGrade')
  floors_above_grade.text = feature[:numberoffloors].to_i
  building.add_element(floors_above_grade)

  floors_below_grade = REXML::Element.new('auc:FloorsBelowGrade')
  floors_below_grade.text = 0 # DLM need to map this?
  building.add_element(floors_below_grade)

  floor_areas = REXML::Element.new('auc:FloorAreas')

  floor_area = REXML::Element.new('auc:FloorArea')
  floor_area_type = REXML::Element.new('auc:FloorAreaType')
  floor_area_type.text = 'Gross'
  floor_area.add_element(floor_area_type)
  floor_area_value = REXML::Element.new('auc:FloorAreaValue')
  floor_area_value.text = convert(feature[:sqft], 'ft2', 'ft2')
  floor_area.add_element(floor_area_value)
  floor_areas.add_element(floor_area)
  
  floor_area = REXML::Element.new('auc:FloorArea')
  floor_area_type = REXML::Element.new('auc:FloorAreaType')
  floor_area_type.text = 'Heated and Cooled'
  floor_area.add_element(floor_area_type)
  floor_area_value = REXML::Element.new('auc:FloorAreaValue')
  floor_area_value.text = convert(feature[:sqft], 'ft2', 'ft2')
  floor_area.add_element(floor_area_value)
  floor_areas.add_element(floor_area)

  building.add_element(floor_areas)

  # year of construction and modified
  year_of_construction = REXML::Element.new('auc:YearOfConstruction')
  year_of_construction.text = get_year_built(feature)
  building.add_element(year_of_construction)

  # subsections
  subsections = REXML::Element.new('auc:Subsections')
  
  # create single subsection
  subsection = REXML::Element.new('auc:Subsection')
  subsection.attributes['ID'] = "Default_Subsection"

  occupancy_classification = REXML::Element.new('auc:OccupancyClassification')
  occupancy_classification.text = get_occupancy_classification(feature)
  subsection.add_element(occupancy_classification)

  occupancy_levels = REXML::Element.new('auc:OccupancyLevels')
  occupancy_level = REXML::Element.new('auc:OccupancyLevel')
  occupant_qty_type = REXML::Element.new('auc:OccupantQuantityType')
 	occupant_qty_type.text = 'Workers on main shift'
 	occupant_qty = REXML::Element.new('auc:OccupantQuantity')
 	occupant_qty.text = feature[:occupants]
 	occupancy_level.add_element(occupant_qty_type)
 	occupancy_level.add_element(occupant_qty)
 	occupancy_levels.add_element(occupancy_level)
 	subsection.add_element(occupancy_levels)
  
  # If you want to put in schedules
  # typical_occupant_usages = REXML::Element.new('auc:TypicalOccupantUsages')
  # typical_occupant_usage = REXML::Element.new('auc:TypicalOccupantUsage')
  # typical_occupant_usage_value = REXML::Element.new('auc:TypicalOccupantUsageValue')
  # typical_occupant_usage_value.text = '40.0'
  # typical_occupant_usage.add_element(typical_occupant_usage_value)
  # typical_occupant_usage_units = REXML::Element.new('auc:TypicalOccupantUsageUnits')
  # typical_occupant_usage_units.text = 'Hours per week'
  # typical_occupant_usage.add_element(typical_occupant_usage_units)
  # typical_occupant_usages.add_element(typical_occupant_usage)
  
  # typical_occupant_usage = REXML::Element.new('auc:TypicalOccupantUsage')
  # typical_occupant_usage_value = REXML::Element.new('auc:TypicalOccupantUsageValue')
  # typical_occupant_usage_value.text = '50.0'
  # typical_occupant_usage.add_element(typical_occupant_usage_value)
  # typical_occupant_usage_units = REXML::Element.new('auc:TypicalOccupantUsageUnits')
  # typical_occupant_usage_units.text = 'Weeks per year'
  # typical_occupant_usage.add_element(typical_occupant_usage_units)
  # typical_occupant_usages.add_element(typical_occupant_usage)
  # subsection.add_element(typical_occupant_usages)

  floor_areas = REXML::Element.new('auc:FloorAreas')

  floor_area = REXML::Element.new('auc:FloorArea')
  floor_area_type = REXML::Element.new('auc:FloorAreaType')
  floor_area_type.text = 'Gross'
  floor_area.add_element(floor_area_type)
  floor_area_value = REXML::Element.new('auc:FloorAreaValue')
  floor_area_value.text = convert(feature[:sqft], 'ft2', 'ft2')
  floor_area.add_element(floor_area_value)
  floor_areas.add_element(floor_area)
 
  floor_area = REXML::Element.new('auc:FloorArea')
  floor_area_type = REXML::Element.new('auc:FloorAreaType')
  floor_area_type.text = 'Common'
  floor_area.add_element(floor_area_type)
  floor_area_value = REXML::Element.new('auc:FloorAreaValue')
  floor_area_value.text = '0.0'
  floor_area.add_element(floor_area_value)
  floor_areas.add_element(floor_area)
  
  subsection.add_element(floor_areas)

  # put it all together
  subsections.add_element(subsection)
  building.add_element(subsections)
  buildings.add_element(building)
  site.add_element(buildings)

  return site

end

def create_system(feature)
  hvac_systems = nil

  if !feature[:heatingtype].nil?

    # add heating system with primary fuel UNLESS value = District Heating, then add a Plant
    # Biomass, District Heating, Electric, Electricity, Gas, Heat Network, and Steam, Oil
    new_fuel = nil
    fuel = feature[:heatingtype].downcase
    case fuel
    when 'electricity'
      new_fuel = 'Electricity'
    when 'electric'
      new_fuel = 'Electricity'
    when 'gas'
      new_fuel = 'Natural Gas'
    when 'oil'
      new_fuel = 'Fuel Oil'
    when 'steam'
      new_fuel = 'Dry steam'  # or Flash steam
    when 'biomass'
      new_fuel = 'Biomass'
    end

    if fuel === 'district heating' || fuel === 'heat network'
      # add plant
      hvac_systems = REXML::Element.new('auc:HVACSystems')
      hvac_system = REXML::Element.new('auc:HVACSystem')
      plants = REXML::Element.new('auc:Plants')
      heating_plants = REXML::Element.new('auc:HeatingPlants')
      heating_plant = REXML::Element.new('auc:HeatingPlant')
      district_heating = REXML::Element.new('auc:DistrictHeating')
      dh_type = REXML::Element.new('auc:DistrictHeatingType')
      dh_type.text = 'Unknown'
      district_heating.add_element(dh_type)
      heating_plant.add_element(district_heating)
      heating_plants.add_element(heating_plant)
      plants.add_element(heating_plants)
      hvac_system.add_element(plants)
      hvac_systems.add_element(hvac_system)

    elsif !new_fuel.nil?
      # add system
      hvac_systems = REXML::Element.new('auc:HVACSystems')
      hvac_system = REXML::Element.new('auc:HVACSystem')
      h_and_c = REXML::Element.new('auc:HeatingAndCoolingSystems')
      heating_sources = REXML::Element.new('auc:HeatingSources')
      heating_source = REXML::Element.new('auc:HeatingSource')
      primary_fuel = REXML::Element.new('auc:PrimaryFuel')
      primary_fuel.text = new_fuel
      heating_source.add_element(primary_fuel)
      heating_sources.add_element(heating_source)
      h_and_c.add_element(heating_sources)
      hvac_system.add_element(h_and_c)
      hvac_systems.add_element(hvac_system)
    end
  end

  return hvac_systems
end

def create_scenario(feature)
  scenario = nil
  if !feature[:energystarscore].nil?
    scenario = REXML::Element.new('auc:Scenario')
    scenario_type = REXML::Element.new('auc:ScenarioType')
    current_building = REXML::Element.new('auc:CurrentBuilding')
    esc = REXML::Element.new('auc:ENERGYSTARScore')
    esc.text = feature[:energystarscore]
    current_building.add_element(esc)
    scenario_type.add_element(current_building)
    scenario.add_element(scenario_type)
  end

  if !feature[:dataend].nil? && !feature[:datastart].nil?
    if scenario.nil?
      scenario = REXML::Element.new('auc:Scenario')
    end
    time_series_data = REXML::Element.new('auc:TimeSeriesData')
    time_series = REXML::Element.new('auc:TimeSeries')
    start_ts = REXML::Element.new('auc:StartTimeStamp')
    end_ts = REXML::Element.new('auc:EndTimeStamp')

    d = feature[:datastart][0,2]
    m = feature[:datastart][3,2]
    y = feature[:datastart][6,2]
    h = feature[:datastart][9,2]
    min = feature[:datastart][12,2]

    start_ts.text = '20' + y + '-' + m + '-' + d + ' ' + h + ':' + min + ':00'


    d = feature[:dataend][0,2]
    m = feature[:dataend][3,2]
    y = feature[:dataend][6,2]
    h = feature[:dataend][9,2]
    min = feature[:dataend][12,2]

    end_ts.text = '20' + y + '-' + m + '-' + d + ' ' + h + ':' + min + ':00'

    time_series.add_element(start_ts)
    time_series.add_element(end_ts)
    time_series_data.add_element(time_series)
    scenario.add_element(time_series_data)

  end

  return scenario
end

def convert_building(feature)

  building_id = get_building_id(feature)
  floor_area = get_floor_area(feature)

  source = '
  <auc:BuildingSync xmlns:auc="http://buildingsync.net/schemas/bedes-auc/2019" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://buildingsync.net/schemas/bedes-auc/2019 https://raw.githubusercontent.com/BuildingSync/schema/v1.0-patch/BuildingSync.xsd">
  	<auc:Facilities>
  		<auc:Facility>
    		<auc:Sites>
    		</auc:Sites> 
        <auc:Systems>
        </auc:Systems>
        <auc:Reports>
          <auc:Report>
          </auc:Report>
        </auc:Reports>
  		</auc:Facility>
	</auc:Facilities>
  </auc:BuildingSync>
  '
  doc = REXML::Document.new(source)
  sites = doc.elements['*/*/*/auc:Sites']
  site = create_site(feature)
  sites.add_element(site)

  # add hvac system if heatingtype is present
  hvac_systems = create_system(feature)
  if !hvac_systems.nil?
    systems = doc.elements['*/*/*/auc:Systems']
    systems.add_element(hvac_systems)
  end

  # add scenario (energystarscore, datastart, dataend?)
  scenario = create_scenario(feature)
  if !scenario.nil?
    report = doc.elements['*/*/*/auc:Reports/auc:Report']
    scenarios = REXML::Element.new('auc:Scenarios')
    scenarios.add_element(scenario)
    report.add_element(scenarios)
  end

  return doc

end

# output directory
outdir = './bdgp_output'
FileUtils.mkdir_p(outdir) unless File.exist?(outdir)

# summary file
summary_file = File.open(outdir + "/bdgp_summary.csv", 'w')
summary_file.puts "building_id,xml_filename,OccupancyClassification,BuildingName,FloorArea(ft2),YearBuilt"

options = {headers:true, 
           header_converters: :symbol}

CSV.foreach(ARGV[0], options) do |feature|
	id = feature[:uid]
	begin
    doc = convert_building(feature)
    filename = File.join(outdir, "#{id}.xml")
    File.open(filename, 'w') do |file|
      doc.write(file)
    end
  rescue => e
    puts "Building #{id} not converted, #{e.message}"
    next
  end

  floor_area = get_floor_area(feature)
  building_type = get_occupancy_classification(feature)
  year_built = get_year_built(feature) # default
    
  building_name = "Building #{id}"
    
  summary_file.puts "#{id},#{id}.xml,#{building_type},#{building_name},#{floor_area},#{year_built}"
  
end