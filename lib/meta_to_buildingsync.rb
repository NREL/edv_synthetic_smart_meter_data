# convert Building Data Genome Project metadata to BuildingSync XML files
# Notes: Dates in csv are in DD/MM/YY format

require 'csv'
require 'rexml/document'
require 'fileutils'
require 'json'
require 'date'
require 'time'
require_relative 'constants'

if ARGV[0].nil? || !File.exist?(ARGV[0])
  puts 'usage: bundle exec ruby meta_to_buildingsync.rb /path/to/csv scenario_file.json'
  puts '.csv files only'
  puts 'scenario_file.json is optional. If provided, it shall be a valid JSON document'
  puts 'The scenario_file.json shall be located in the INPUT_DIR directory.'
  puts "The key shall designate the BDGP 'primary_building_type' column, and the value"
  puts "shall designate the desired OpenStudio occupancy classification."
  puts 'Valid values for primary_building_type: Office, College Classroom, Primary/Secondary Classroom, '
  puts 'College Laboratory, Dormitory.  Valid values for OpenStudio occupancy classifications'
  puts 'are maintained in the BuildingSync-gem spec/tests/model_articulation/occupancy_types_spec.rb'
  exit(1)

end

occ_classification_file = INPUT_DIR + '/default_scenario.json'
state_hash_file = INPUT_DIR + "/state_hash.json"
scenario_hash = nil
if !ARGV[1].nil?
  if File.exist?(ARGV[1])
    occ_classification_file = "#{ARGV[1]}"
  else
    puts 'usage: bundle exec ruby meta_to_buildingsync.rb /path/to/csv scenario_file.json'
    puts '.csv files only'
    puts 'scenario_file.json is optional. If provided, it shall be a valid JSON document'
    puts 'The scenario_file.json shall be located in the INPUT_DIR directory.'
    puts "The key shall designate the BDGP 'primary_building_type' column, and the value"
    puts "shall designate the desired OpenStudio occupancy classification."
    puts 'Valid values for primary_building_type: Office, College Classroom, Primary/Secondary Classroom, '
    puts 'College Laboratory, Dormitory.  Valid values for OpenStudio occupancy classifications'
    puts 'are maintained in the BuildingSync-gem spec/tests/model_articulation/occupancy_types_spec.rb'
    exit(1)
  end
else
  if !File.exists?(occ_classification_file)
    puts "#{occ_classification_file} does not exist."
    occ_classification_file = nil
  else
    puts "No scenario file provided.  Using #{occ_classification_file}"
  end

end

def xml_namespace()
  'xmlns:auc="http://buildingsync.net/schemas/bedes-auc/2019" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://buildingsync.net/schemas/bedes-auc/2019 https://raw.githubusercontent.com/BuildingSync/schema/v2.0/BuildingSync.xsd" version="2.0.0"'
end

def convert(value, unit_in, unit_out)
  raise 'No value to convert' if value.nil?

  if unit_in == unit_out
  elsif unit_in == 'm'
    value = 3.28084 * value if unit_out == 'ft'
  elsif unit_in == 'm2'
    value = 10.7639 * value if unit_out == 'ft2'
  end
  value
end

def get_building_id(feature)

  feature[:building_id]

end

def get_floor_area(feature)

  feature[:floor_area_sqft]

  raise 'Floor Area (SQFT) is empty' if feature[:floor_area_sqft].nil?

  convert(feature[:floor_area_sqft], 'ft2', 'ft2')
end

def get_year_built(feature)
  # remove "pre" and "post"
  yr_blt = feature[:vintage]

  unless yr_blt.nil?
    yr_blt.gsub('pre ', '')
    yr_blt.gsub('Pre ', '')
    yr_blt.gsub('post ', '')
    yr_blt.gsub('Post ', '')

    # take last number if given a range
    yrs = yr_blt.split('-')
    yr_blt = yrs[-1]
  end
  if !/\A\d+\z/.match(yr_blt)
    return ''
  else
    return yr_blt
  end
end

def get_climate_zone(feature)
  # remove "pre" and "post"
  return feature[:climate_zone]
end

def get_building_classification(feature)

  classification = feature[:primary_building_type]
  #TODO: need more extension of classifications depending on the building type classified in the data source

  result = nil
  case classification
  when 'Office'
    result = 'Commercial'
  when'Retail Store'
    result = 'Commercial'
  when 'Primary/Secondary Classroom'
    result = 'Commercial'
  when 'College Classroom'
    result = 'Commercial'
  when 'Dormitory'
    result = 'Commercial'
  when 'College Laboratory'
    result = 'Commercial'
  when 'Retail'
    result = 'Commercial'
  when 'Education'
    result = 'Commercial'
  when 'Lodging/residential'
    result = 'Commercial'
  when 'Entertainment/public assembly'
    result = 'Commercial'
  when 'Services'
    result = 'Commercial'
  when 'Public services'
    result = 'Commercial'
  when 'Utility'
    result = 'Commercial'
  when 'Parking'
    result = 'Commercial'
  when 'Healthcare'
    result = 'Commercial'
  when 'Food sales and service'
    result = 'Commercial'
  when 'Manufacturing/industrial'
    result = 'Industrial'
  when 'Warehouse/storage'
    result = 'Commercial'
  when 'Religious worship'
    result = 'Commercial'
  when 'Technology/science'
    result = 'Commercial'
  when 'Other'
    result = 'Commercial'
  when 'Strip Mall'
    result = 'Commercial'
  else
    raise "Unknown classification #{classification}"
  end

  result
end

def get_occupancy_classification(feature, scenario_hash = nil)

  classification = feature[:primary_building_type]

  result = nil
  case classification
  when 'Office'
    result = scenario_hash[:"Office"]
  when 'Retail Store'
    result = scenario_hash[:"Retail"]
  when 'Retail'
	result = scenario_hash[:"Retail"]
  when 'Primary/Secondary Classroom'
    result = scenario_hash[:"PrimarySchool"]
  when 'College Classroom'
    result = scenario_hash[:"College Classroom"]
  when 'Dormitory'
    result = scenario_hash[:"Multifamily"]
  when 'College Laboratory'
    result = scenario_hash[:"College Laboratory"]
  when 'Education'
	result = scenario_hash[:"PrimarySchool"]
  when 'Lodging/residential'
	result = scenario_hash[:"Lodging with extended amenities"]
  when 'Entertainment/public assembly'
	result = scenario_hash[:"Office"]
  when 'Services'
	result = scenario_hash[:"Office"]
  when 'Public services'
	result = scenario_hash[:"Office"]
  when 'Utility'
	result = scenario_hash[:"Office"]
  when 'Parking'
	result = scenario_hash[:"Parking"]
  when 'Healthcare'
	result = scenario_hash[:"Hospital"]
  when 'Food sales and service'
	result = scenario_hash[:"Food service"]
  when 'Manufacturing/industrial'
	result = scenario_hash[:"Office"]
  when 'Warehouse/storage'
	result = scenario_hash[:"Warehouse"]
  when 'Religious worship'
	result = scenario_hash[:"Office"]
  when 'Technology/science'
    result = scenario_hash[:"Office"]
  when 'Other'
    result = scenario_hash[:"Office"]
  when 'Strip Mall'
    result = scenario_hash[:"Office"]
  else
    raise "Unknown classification #{classification}"
  end
  if result.nil?
    result = "Office"
  end
  return result
end

def json_to_hash(json_file)
  begin
    File.open(json_file, 'r') do |file|
      hash = JSON.parse(file.read, symbolize_names: true)
      return hash
    end
  rescue => e
    puts "Unable to read file #{json_file}.  Exiting."
    puts e.message
    exit(1)
  end
end

def create_site(feature, scenario_hash = nil, state_hash)
  site = REXML::Element.new('auc:Site')
  feature_id = get_building_id(feature)
  raise 'Building ID is empty' if feature_id.nil?

  if feature.key?(:zipcode) || feature.key?(:city) || feature.key?(:us_state)
    address = REXML::Element.new('auc:Address')

    if feature.key?(:city) && !feature[:city].nil?
      city = REXML::Element.new('auc:City')
      city.text = feature[:city]
      address.add_element(city)
    end

    country = nil
    if feature.key?(:us_state) && !feature[:us_state].nil?
      st = feature[:us_state]
      not_states = {
          "Wales" => "Wales",
          "England" => "England",
          "Zurich" => "Switzerland"
      }
      v = not_states[st]
      country = REXML::Element.new('auc:Country')
      if !v.nil?
        country.text = v
      else
        state_abbrev = state_hash.key(feature[:us_state])
        if state_abbrev.nil? || state_abbrev == ''
        else
          state = REXML::Element.new('auc:State')
          state.text = state_abbrev
          address.add_element(state)
          country.text = "USA"
        end
      end
    end

    # zipcode (if present)
    if feature.key?(:zipcode) && /\A\d+\z/.match(feature[:zipcode])
      postal_code = REXML::Element.new('auc:PostalCode')
      postal_code.text = feature[:zipcode]
      address.add_element(postal_code)
    end

    if !country.nil?
      address.add_element(country)
    end
    site.add_element(address)
  end

  # climate zone
  if feature.key?(:climate_zone) && !feature[:climate_zone].nil?
    climate_zone = REXML::Element.new('auc:ClimateZoneType')
    ashrae = REXML::Element.new('auc:ASHRAE')
    ashrae_climate = REXML::Element.new('auc:ClimateZone')
    ashrae_climate.text = feature[:climate_zone]
    ashrae.add_element(ashrae_climate)
    climate_zone.add_element(ashrae)
    site.add_element(climate_zone)
  end

  # lat/lng (if present)
  if feature.key?(:longitude) && !feature[:longitude].nil?
    longitude = REXML::Element.new('auc:Longitude')
    longitude.text = feature[:longitude]
    site.add_element(longitude)
  end

  # latitude (if present)
  if feature.key?(:latitude) && !feature[:latitude].nil?
    latitude = REXML::Element.new('auc:Latitude')
    latitude.text = feature[:latitude]
    site.add_element(latitude)
  end

  # ownership
  ownership = REXML::Element.new('auc:Ownership')
  ownership.text = 'Unknown'
  site.add_element(ownership)

  # buildings
  buildings = REXML::Element.new('auc:Buildings')
  building = REXML::Element.new('auc:Building')
  building.attributes['ID'] = feature_id

  # default name
  feature[:nickname] = 'Building' if feature[:nickname].nil?
  raise 'Building Nickname is not set' if feature[:nickname].nil?

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
  occupancy_classification.text = get_occupancy_classification(feature, scenario_hash)
  building.add_element(occupancy_classification)

  floors_above_grade = REXML::Element.new('auc:FloorsAboveGrade')
  number_of_floors = [feature[:number_of_stories].to_i, 1].max # DLM: assume 1 story if no information

  floors_above_grade.text = number_of_floors
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
  floor_area_value.text = convert(feature[:floor_area_sqft], 'ft2', 'ft2')
  floor_area.add_element(floor_area_value)
  floor_areas.add_element(floor_area)

  floor_area = REXML::Element.new('auc:FloorArea')
  floor_area_type = REXML::Element.new('auc:FloorAreaType')
  floor_area_type.text = 'Heated and Cooled'
  floor_area.add_element(floor_area_type)
  floor_area_value = REXML::Element.new('auc:FloorAreaValue')
  floor_area_value.text = convert(feature[:floor_area_sqft], 'ft2', 'ft2')
  floor_area.add_element(floor_area_value)
  floor_areas.add_element(floor_area)

  building.add_element(floor_areas)

  # year of construction and modified
  year_of_construction = REXML::Element.new('auc:YearOfConstruction')
  year_of_construction.text = get_year_built(feature)
  if year_of_construction.text.nil? || year_of_construction.text == ''
    def_year = 1980
    puts "No built year provided, setting to default year: #{def_year}"
    year_of_construction.text = def_year
  end
  building.add_element(year_of_construction)

  subsections = REXML::Element.new('auc:Sections')
  # create single subsection
  subsection = REXML::Element.new('auc:Section')
  subsection.attributes['ID'] = 'Default_Section'

  occupancy_classification = REXML::Element.new('auc:OccupancyClassification')
  occupancy_classification.text = get_occupancy_classification(feature, scenario_hash)
  subsection.add_element(occupancy_classification)

  if feature[:number_of_occupants]
    occupancy_levels = REXML::Element.new('auc:OccupancyLevels')
    occupancy_level = REXML::Element.new('auc:OccupancyLevel')
    occupant_qty_type = REXML::Element.new('auc:OccupantQuantityType')
    occupant_qty_type.text = 'Workers on main shift'
    occupant_qty = REXML::Element.new('auc:OccupantQuantity')
    occupant_qty.text = feature[:number_of_occupants]
    occupancy_level.add_element(occupant_qty_type)
    occupancy_level.add_element(occupant_qty)
    occupancy_levels.add_element(occupancy_level)
    subsection.add_element(occupancy_levels)
  end

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
  floor_area_value.text = convert(feature[:floor_area_sqft], 'ft2', 'ft2')
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

  site

end

def create_system(feature)
  hvac_systems = nil

  unless feature[:fuel_type].nil?
    hvac_systems = REXML::Element.new('auc:HVACSystems')

    feature[:fuel_type].split('/').each do |fuel|

      # add heating system with primary fuel UNLESS value = District Heating, then add a Plant
      # Biomass, District Heating, Electric, Electricity, Gas, Heat Network, and Steam, Oil
      new_fuel = nil
      # fuel = feature[:fuel_type].downcase
      case fuel
        when 'electricity'
          new_fuel = 'Electricity'
        when 'electric'
          new_fuel = 'Electricity'
        when 'gas'
          new_fuel = 'Natural gas'
        when 'oil'
          new_fuel = 'Fuel oil'
        when 'steam'
          new_fuel = 'Dry steam' # or Flash steam
        when 'biomass'
          new_fuel = 'Biomass'
      end

      if fuel === 'district heating' || fuel === 'heat network'
        # add plant
        # hvac_systems = REXML::Element.new('auc:HVACSystems')
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
        # hvac_systems.add_element(hvac_system)

      elsif !new_fuel.nil?
        # add system
        # hvac_systems = REXML::Element.new('auc:HVACSystems')
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
        # hvac_systems.add_element(hvac_system)
      end
      hvac_systems.add_element(hvac_system)
    end
  end

  hvac_systems
end

def create_measures(feature)
  building_id = get_building_id(feature)
  floor_area = get_floor_area(feature).to_f

  measures = []
  # measures << {ID: 'Measure1',
  #              SingleMeasure: true,
  #              SystemCategoryAffected: 'Lighting',
  #              TechnologyCategory: 'LightingImprovements',
  #              MeasureName: 'Retrofit with light emitting diode technologies',
  #              LongDescription: 'Retrofit with light emitting diode technologies',
  #              ScenarioName: 'LED',
  #              OpenStudioMeasureName: 'TBD',
  #              UsefulLife: 12,
  #              MeasureTotalFirstCost: 3.85 * floor_area}

  # measures << {ID: 'Measure2',
  #              SingleMeasure: true,
  #              SystemCategoryAffected: 'Plug Load',
  #              TechnologyCategory: 'PlugLoadReductions',
  #              MeasureName: 'Replace with ENERGY STAR rated',
  #              LongDescription: 'Replace with ENERGY STAR rated',
  #              ScenarioName: 'Electric_Appliance_30%_Reduction',
  #              OpenStudioMeasureName: 'TBD',
  #              UsefulLife: 9,
  #              MeasureTotalFirstCost: 0.51 * floor_area}

  # measures << {ID: 'Measure3',
  #              SingleMeasure: true,
  #              SystemCategoryAffected: 'Wall',
  #              TechnologyCategory: 'BuildingEnvelopeModifications',
  #              MeasureName: 'Air seal envelope',
  #              LongDescription: 'Air seal envelope',
  #              ScenarioName: 'Air_Seal_Infiltration_30%_More_Airtight',
  #              OpenStudioMeasureName: 'TBD',
  #              UsefulLife: 11,
  #              MeasureTotalFirstCost: 2.34 * floor_area}

  # measures << {ID: 'Measure4',
  #              SingleMeasure: true,
  #              SystemCategoryAffected: 'Cooling System',
  #              TechnologyCategory: 'OtherHVAC',
  #              MeasureName: 'Replace package units',
  #              LongDescription: 'Replace package units',
  #              ScenarioName: 'Cooling_System_SEER 14',
  #              OpenStudioMeasureName: 'TBD',
  #              UsefulLife: 15,
  #              MeasureTotalFirstCost: 4.18 * floor_area}

  # measures << {ID: 'Measure5',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Heating System',
  # TechnologyCategory: 'OtherHVAC',
  # MeasureName: 'Replace burner',
  # LongDescription: 'Replace burner',
  # ScenarioName: 'Heating_System_Efficiency_0.93',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 20,
  # MeasureTotalFirstCost: 0.89*floor_area}

  # measures << {ID: 'Measure6',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Lighting',
  # TechnologyCategory: 'LightingImprovements',
  # MeasureName: 'Add daylight controls',
  # LongDescription: 'Add daylight controls',
  # ScenarioName: 'Add daylight controls',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 8,
  # MeasureTotalFirstCost: 0.53*floor_area}

  # measures << {ID: 'Measure7',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Lighting',
  # TechnologyCategory: 'LightingImprovements',
  # MeasureName: 'Add occupancy sensors',
  # LongDescription: 'Add occupancy sensors',
  # ScenarioName: 'Add occupancy sensors',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 8,
  # MeasureTotalFirstCost: 1.55*floor_area}

  # measures << {ID: 'Measure8',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Plug Load',
  # TechnologyCategory: 'PlugLoadReductions',
  # MeasureName: 'Install plug load controls',
  # LongDescription: 'Install plug load controls',
  # ScenarioName: 'Install plug load controls',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 5.6,
  # MeasureTotalFirstCost: 0.82*floor_area}

  # measures << {ID: 'Measure9',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Wall',
  # TechnologyCategory: 'BuildingEnvelopeModifications',
  # MeasureName: 'Increase wall insulation',
  # LongDescription: 'Increase wall insulation',
  # ScenarioName: 'Increase wall insulation',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 20,
  # MeasureTotalFirstCost: 1.63*floor_area}

  # measures << {ID: 'Measure10',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Wall',
  # TechnologyCategory: 'BuildingEnvelopeModifications',
  # MeasureName: 'Insulate thermal bypasses',
  # LongDescription: 'Insulate thermal bypasses',
  # ScenarioName: 'Insulate thermal bypasses',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 20,
  # MeasureTotalFirstCost: 1.00*floor_area}

  # measures << {ID: 'Measure11',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Roof',
  # TechnologyCategory: 'BuildingEnvelopeModifications',
  # MeasureName: 'Increase roof insulation',
  # LongDescription: 'Increase roof insulation',
  # ScenarioName: 'Increase roof insulation',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 20,
  # MeasureTotalFirstCost: 14.46*floor_area}

  # measures << {ID: 'Measure12',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Ceiling',
  # TechnologyCategory: 'BuildingEnvelopeModifications',
  # MeasureName: 'Increase ceiling insulation',
  # LongDescription: 'Increase ceiling insulation',
  # ScenarioName: 'Increase ceiling insulation',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 20,
  # MeasureTotalFirstCost: 2.67*floor_area}

  # measures << {ID: 'Measure13',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Fenestration',
  # TechnologyCategory: 'BuildingEnvelopeModifications',
  # MeasureName: 'Add window films',
  # LongDescription: 'Add window films',
  # ScenarioName: 'Add window films',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 10,
  # MeasureTotalFirstCost: 1.00*floor_area}

  # measures << {ID: 'Measure14',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'General Controls and Operations',
  # TechnologyCategory: 'OtherHVAC',
  # MeasureName: 'Upgrade operating protocols, calibration, and/or sequencing',
  # LongDescription: 'Upgrade operating protocols, calibration, and/or sequencing',
  # ScenarioName: 'Upgrade operating protocols calibration and-or sequencing',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 11,
  # MeasureTotalFirstCost: 0.005*floor_area}

  # measures << {ID: 'Measure15',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Domestic Hot Water',
  # TechnologyCategory: 'ChilledWaterHotWaterAndSteamDistributionSystems',
  # MeasureName: 'Replace or upgrade water heater',
  # LongDescription: 'Replace or upgrade water heater',
  # ScenarioName: 'Replace or upgrade water heater',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 10,
  # MeasureTotalFirstCost: 0.17*floor_area}

  # measures << {ID: 'Measure16',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Refrigeration',
  # TechnologyCategory: 'Refrigeration',
  # MeasureName: 'Replace ice/refrigeration equipment with high efficiency units',
  # LongDescription: 'Replace ice/refrigeration equipment with high efficiency units',
  # ScenarioName: 'Replace ice-refrigeration equipment with high efficiency units',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 12.5,
  # MeasureTotalFirstCost: 1.95*floor_area}

  # measures << {ID: 'Measure17',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Fenestration',
  # TechnologyCategory: 'BuildingEnvelopeModifications',
  # MeasureName: 'Replace windows',
  # LongDescription: 'Replace windows',
  # ScenarioName: 'Replace windows',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 20,
  # MeasureTotalFirstCost: 2.23*floor_area}

  # measures << {ID: 'Measure18',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Heating System',  # TechnologyCategory: 'BoilerPlantImprovements',
  # MeasureName: 'Replace boiler',
  # LongDescription: 'Replace boiler',
  # ScenarioName: 'Replace boiler',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 20,
  # MeasureTotalFirstCost: 0.95*floor_area}

  # measures << {ID: 'Measure19',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Other HVAC',
  # TechnologyCategory: 'OtherHVAC',
  # MeasureName: 'Replace AC and heating units with ground coupled heat pump systems',
  # LongDescription: 'Replace AC and heating units with ground coupled heat pump systems',
  # ScenarioName: 'Replace HVAC with GSHP and DOAS',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 15,
  # MeasureTotalFirstCost: 14.00*floor_area}

  # measures << {ID: 'Measure20',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Other HVAC',
  # TechnologyCategory: 'OtherHVAC',
  # MeasureName: 'Other',
  # LongDescription: 'VRF with DOAS',
  # ScenarioName: 'VRF with DOAS',
  # OpenStudioMeasureName: 'Replace HVAC system type to VRF',
  # UsefulLife: 10,
  # MeasureTotalFirstCost: 16.66*floor_area}

  # measures << {ID: 'Measure21',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Other HVAC',
  # TechnologyCategory: 'OtherHVAC',
  # MeasureName: 'Other',
  # LongDescription: 'Replace HVAC system type to PZHP',
  # ScenarioName: 'Replace HVAC system type to PZHP',
  # OpenStudioMeasureName: 'Replace HVAC system type to PZHP',
  # UsefulLife: 15,
  # MeasureTotalFirstCost: 4.26*floor_area}

  # measures << {ID: 'Measure22',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Fan',
  # TechnologyCategory: 'OtherElectricMotorsAndDrives',
  # MeasureName: 'Replace with higher efficiency',
  # LongDescription: 'Replace with higher efficiency',
  # ScenarioName: 'Replace with higher efficiency',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 15,
  # MeasureTotalFirstCost: 10.75*floor_area}

  # measures << {ID: 'Measure23',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Air Distribution',
  # TechnologyCategory: 'OtherHVAC',
  # MeasureName: 'Improve ventilation fans',
  # LongDescription: 'Improve ventilation fans',
  # ScenarioName: 'Improve ventilation fans',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 4.4,
  # MeasureTotalFirstCost: 1.00*floor_area}

  # measures << {ID: 'Measure24',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Air Distribution',
  # TechnologyCategory: 'OtherHVAC',
  # MeasureName: 'Install demand control ventilation',
  # LongDescription: 'Install demand control ventilation',
  # ScenarioName: 'Install demand control ventilation',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 10,
  # MeasureTotalFirstCost: 0.33*floor_area}

  # measures << {ID: 'Measure25',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Air Distribution',
  # TechnologyCategory: 'OtherHVAC',
  # MeasureName: 'Add or repair economizer',
  # LongDescription: 'Add or repair economizer',
  # ScenarioName: 'Add or repair economizer',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 12.5,
  # MeasureTotalFirstCost: 0.80*floor_area}

  # measures << {ID: 'Measure26',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Heat Recovery',
  # TechnologyCategory: 'OtherHVAC',
  # MeasureName: 'Add energy recovery',
  # LongDescription: 'Add energy recovery',
  # ScenarioName: 'Add energy recovery',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 14,
  # MeasureTotalFirstCost: 4.53*floor_area}

  # measures << {ID: 'Measure27',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Domestic Hot Water',
  # TechnologyCategory: 'ChilledWaterHotWaterAndSteamDistributionSystems',
  # MeasureName: 'Add pipe insulation',
  # LongDescription: 'Add pipe insulation',
  # ScenarioName: 'Add pipe insulation',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 12,
  # MeasureTotalFirstCost: 0.14*floor_area}

  # measures << {ID: 'Measure28',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Domestic Hot Water',
  # TechnologyCategory: 'ChilledWaterHotWaterAndSteamDistributionSystems',
  # MeasureName: 'Add recirculating pumps',
  # LongDescription: 'Add recirculating pumps',
  # ScenarioName: 'Add recirculating pumps',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 15,
  # MeasureTotalFirstCost: 0.18*floor_area}

  # measures << {ID: 'Measure29',
  # SingleMeasure: true,
  # SystemCategoryAffected: 'Water Use',
  # TechnologyCategory: 'WaterAndSewerConservationSystems',
  # MeasureName: 'Install low-flow faucets and showerheads',
  # LongDescription: 'Install low-flow faucets and showerheads',
  # ScenarioName: 'Install low-flow faucets and showerheads',
  # OpenStudioMeasureName: 'TBD',
  # UsefulLife: 10,
  # MeasureTotalFirstCost: 1.00*floor_area}

  packages = []
  packages << {ScenarioName: 'All Package',
               MeasureIDs: ['Measure1', 'Measure2', 'Measure3', 'Measure4']}

  # create unique measures for each package
  packages.each_index do |i|
    package = packages[i]
    this_measures = []
    package[:MeasureIDs].each do |measureID|
      measures.each do |measure|
        this_measures << measure if measure[:ID] == measureID
      end
    end

    #puts "Package: #{package[:ScenarioName]}"
    new_measure_ids = []
    this_measures.each do |this_measure|
      #puts "  #{this_measure[:MeasureName]}"
      new_measure = this_measure.clone
      new_measure_id = new_measure[:ID] + "_Package#{i}"
      new_measure_ids << new_measure_id
      new_measure[:ID] = new_measure_id
      new_measure[:LongDescription] = new_measure[:LongDescription] + " Package#{i}"
      new_measure[:SingleMeasure] = false
      new_measure[:ScenarioName] = package[:ScenarioName]
      measures << new_measure
    end
    package[:MeasureIDs] = new_measure_ids
  end

  result = REXML::Element.new('auc:Measures')

  # add measures
  measures.each do |measure|
    text = "<auc:Measure ID=\"#{measure[:ID]}\" #{xml_namespace}>
        <auc:SystemCategoryAffected>#{measure[:SystemCategoryAffected]}</auc:SystemCategoryAffected>
			  <auc:LinkedPremises>
					<auc:Building>
						<auc:LinkedBuildingID IDref=\"#{building_id}\"/>
					</auc:Building>
				</auc:LinkedPremises>
        <auc:TechnologyCategories>
          <auc:TechnologyCategory>
            <auc:#{measure[:TechnologyCategory]}>
              <auc:MeasureName>#{measure[:MeasureName]}</auc:MeasureName>
            </auc:#{measure[:TechnologyCategory]}>
          </auc:TechnologyCategory>
        </auc:TechnologyCategories>
        <auc:MeasureScaleOfApplication>Entire building</auc:MeasureScaleOfApplication>
        <auc:LongDescription>#{measure[:LongDescription]}</auc:LongDescription>
        <auc:MVCost>0</auc:MVCost>
        <auc:UsefulLife>#{measure[:UsefulLife]}</auc:UsefulLife>
        <auc:MeasureTotalFirstCost>#{measure[:MeasureTotalFirstCost]}</auc:MeasureTotalFirstCost>
        <auc:MeasureInstallationCost>0</auc:MeasureInstallationCost>
        <auc:MeasureMaterialCost>0</auc:MeasureMaterialCost>
        <auc:Recommended>true</auc:Recommended>
        <auc:ImplementationStatus>Proposed</auc:ImplementationStatus>
        <auc:UserDefinedFields>
          <auc:UserDefinedField>
            <auc:FieldName>OpenStudioMeasureName</auc:FieldName>
            <auc:FieldValue>#{measure[:OpenStudioMeasureName]}</auc:FieldValue>
          </auc:UserDefinedField>
        </auc:UserDefinedFields>
      </auc:Measure>"

    element = REXML::Document.new(text)
    element = element.root.delete_namespace('auc').delete_namespace('xsi').delete_attribute('xsi:schemaLocation')
    result.add_element(element)
  end

  $Measures = measures
  $Packages = packages

  result
end

def create_scenarios(feature)

  scenarios = REXML::Element.new('auc:Scenarios')
  scenario = nil

  if !feature[:energystar_score].nil?
    scenario = REXML::Element.new('auc:Scenario')
    scenario_type = REXML::Element.new('auc:ScenarioType')
    current_building = REXML::Element.new('auc:CurrentBuilding')
    esc = REXML::Element.new('auc:ENERGYSTARScore')
    esc.text = feature[:energystar_score]
    current_building.add_element(esc)
    scenario_type.add_element(current_building)
    scenario.add_element(scenario_type)
  end

  if !feature[:measurement_end_date].nil? && !feature[:measurement_start_date].nil?
    scenario = REXML::Element.new('auc:Scenario') if scenario.nil?
    time_series_data = REXML::Element.new('auc:TimeSeriesData')

    time_series = REXML::Element.new('auc:TimeSeries')
    start_ts = REXML::Element.new('auc:StartTimestamp')
    end_ts = REXML::Element.new('auc:EndTimestamp')

    start_date = DateTime.parse(feature[:measurement_start_date])
    d = start_date.day
    m = start_date.month
    y = start_date.year
    h = start_date.hour
    min = start_date.minute

    start_ts.text = start_date

    end_date = DateTime.parse(feature[:measurement_end_date])
    d = end_date.day
    m = end_date.month
    y = end_date.year
    h = end_date.hour
    min = end_date.minute

    end_ts.text = end_date

    time_series.add_element(start_ts)
    time_series.add_element(end_ts)
    time_series_data.add_element(time_series)
    scenario.add_element(time_series_data)
  end

  # annual_total = 0

  # feature.headers.each do |header|
    # if header.match(/seed_2018_([1-9]|1[0-2])_elec_kwh/)
      # time_series = REXML::Element.new('auc:TimeSeries')

      # reading_type = REXML::Element.new('auc:RedingType')
      # reading_type.text = 'Total'

      # reading_quantity = REXML::Element.new('auc:TimeSeriesReadingQuantity')
      # reading_quantity.text = 'Energy'

      # start_ts = REXML::Element.new('auc:StartTimeStamp')
      # end_ts = REXML::Element.new('auc:EndTimeStamp')

      # interval_frequency = REXML::Element.new('auc:IntervalFrequency')
      # interval_frequency.text = 'Month'

      # interval_reading = REXML::Element.new('auc:IntervalReading')
      # interval_reading.text = feature[header]
      # m = header.to_s.scan(/seed_2018_([1-9]|1[0-2])_elec_kwh/).join('')
      # annual_total += interval_reading.text.to_f
      # d = Date.new(2018, m.to_i, -1).day
# #      puts "#{Date::MONTHNAMES[m.to_i]}: #{Date.new(2018, m.to_i, -1).day}"
      # start_ts.text = '2018' + '-' + '%02d'%m + '-' + '1' + ' 00:00:00'
      # end_ts.text = '2018' + '-' + '%02d'%m + '-' + d.to_s + ' 23:00:00+00:00'

      # time_series.add_element(reading_type)
      # time_series.add_element(reading_quantity)
      # time_series.add_element(start_ts)
      # time_series.add_element(end_ts)
      # time_series.add_element(interval_frequency)
      # time_series.add_element(interval_reading)
      # time_series_data.add_element(time_series)
    # end
  # end

  # puts "annual_#{feature[:id]}: #{annual_total}"
  # scenario.add_element(time_series_data)

  # # add resource type
  # resource_uses = REXML::Element.new('auc:ResourceUses')

  # # electricity time series data
  # resource_use = REXML::Element.new('auc:ResourceUse')
  # energy_resource = REXML::Element.new('auc:EnergyResource')
  # energy_resource.text = 'Electrity'
  # resource_units = REXML::Element.new("auc:ResourceUnits")
  # resource_units.text = 'kBtu'
  # annual_fuel_use_native_units = REXML::Element.new("auc:AnnualFuelUseNativeUnits")
  # annual_fuel_use_native_units.text = annual_total * 3.412
  # resource_unit = REXML::Element.new('auc:ResourceUnits')
  # resource_unit.text = 'kW'
  # resource_use.add_element(energy_resource)
  # resource_use.add_element(resource_unit)
  # resource_uses.add_element(resource_use)
  # scenario.add_element(resource_uses)

  scenario = REXML::Element.new('auc:Scenario') if scenario.nil?
  scenarios.add_element(scenario)

  # # add electricity total
  # all_elec_totals = REXML::Element.new('auc:AllResourceTotals')

  # feature.headers.each do |header|
    # if header.match(/seed_2018_([1-9]|1[0-2])_elec_kwh/)
      # all_elec_total = REXML::Element.new('auc:AllResourceTotal')
      # # add EndUse
      # # add ReourceBoundary
      # m = header.to_s.scan(/seed_2018_([1-9]|1[0-2])_elec_kwh/).join('')
      # site_energy_use = REXML::Element.new('auc:SiteEnergyUse')
      # site_energy_use.text = feature[header]
      # # add EnergyCost
      # # add UDFs
      # all_elec_total.add_element(site_energy_use)
      # all_elec_totals.add_element(all_elec_total)
    # end
  # end
  
  # scenario.add_element(all_elec_totals)

  # # add gas time series data and totals
  # scenario_gas = REXML::Element.new('auc:Scenario')
  # time_series_data_gas = REXML::Element.new('auc:TimeSeriesData')

  # # add resource type
  # resource_uses_gas = REXML::Element.new('auc:ResourceUses')

  # # electricity time series data
  # resource_use_gas = REXML::Element.new('auc:ResourceUse')
  # energy_resource_gas = REXML::Element.new('auc:EnergyResource')
  # energy_resource_gas.text = 'Gas'
  # resource_unit_therm = REXML::Element.new('auc:ResourceUnits')
  # resource_unit_therm.text = 'therm'
  # resource_use_gas.add_element(energy_resource_gas)
  # resource_use_gas.add_element(resource_unit_therm)
  # resource_uses_gas.add_element(resource_use_gas)
  # scenario_gas.add_element(resource_uses_gas)

  # feature.headers.each do |header|
    # if header.match(/seed_2018_([1-9]|1[0-2])_gas_therm/)
      # time_series = REXML::Element.new('auc:TimeSeries')
      # start_ts = REXML::Element.new('auc:StartTimeStamp')
      # end_ts = REXML::Element.new('auc:EndTimeStamp')

      # m = header.to_s.scan(/seed_2018_([1-9]|1[0-2])_gas_therm/).join('')
      # d = Date.new(2018, m.to_i, -1).day
#      puts "#{Date::MONTHNAMES[m.to_i]}: #{Date.new(2018, m.to_i, -1).day}"
      # start_ts.text = '2018' + '-' + m + '-' + '1' + ' 00:00:00'
      # end_ts.text = '2018' + '-' + m + '-' + d.to_s + ' 23:59:59'

      # time_series.add_element(start_ts)
      # time_series.add_element(end_ts)
      # time_series_data_gas.add_element(time_series)
    # end
  # end

  # scenario_gas.add_element(time_series_data_gas)

  # # add gas total
  # all_gas_totals = REXML::Element.new('auc:AllResourceTotals')

  # feature.headers.each do |header|
    # if header.match(/seed_2018_([1-9]|1[0-2])_gas_therm/)
      # all_gas_total = REXML::Element.new('auc:AllResourceTotal')
      # # add EndUse
      # # add ReourceBoundary
      # m = header.to_s.scan(/seed_2018_([1-9]|1[0-2])_gas_therm/).join('')
      # site_energy_use = REXML::Element.new('auc:SiteEnergyUse')
      # site_energy_use.text = feature[header]
      # # add EnergyCost
      # # add UDFs
      # all_gas_total.add_element(site_energy_use)
      # all_gas_totals.add_element(all_gas_total)
    # end
  # end
  
  # scenario_gas.add_element(all_gas_totals)
  # scenarios.add_element(scenario_gas)

  # add baseline scenario
  text = "<auc:Scenario ID=\"Baseline\" #{xml_namespace}>
            <auc:ScenarioName>Baseline</auc:ScenarioName>
            <auc:ScenarioType>
              <auc:PackageOfMeasures>
                <auc:ReferenceCase IDref=\"Baseline\"/>
              </auc:PackageOfMeasures>
            </auc:ScenarioType>
          </auc:Scenario>"
  element = REXML::Document.new(text)
  element = element.root.delete_namespace('auc').delete_namespace('xsi').delete_attribute('xsi:schemaLocation')
  scenarios.add_element(element)

  building_id = get_building_id(feature)

  # add single measures
  measures = $Measures
  measures.each do |measure|

    # skip duplicate measures added for packages
    next unless measure[:SingleMeasure]

    text = "<auc:Scenario #{xml_namespace}>
          <auc:ScenarioName>#{measure[:ScenarioName]} Only</auc:ScenarioName>
          <auc:ScenarioType>
            <auc:PackageOfMeasures>
              <auc:ReferenceCase IDref=\"Baseline\"/>
              <auc:MeasureIDs>
                <auc:MeasureID IDref=\"#{measure[:ID]}\"/>
              </auc:MeasureIDs>
            </auc:PackageOfMeasures>
          </auc:ScenarioType>
          <auc:LinkedPremises>
						<auc:Building>
							<auc:LinkedBuildingID IDref=\"#{building_id}\"/>
						</auc:Building>
					</auc:LinkedPremises>
					<auc:UserDefinedFields>
						<auc:UserDefinedField>
							<auc:FieldName>Recommendation Category</auc:FieldName>
							<auc:FieldValue>Potential Capital Recommendations</auc:FieldValue>
						</auc:UserDefinedField>
					</auc:UserDefinedFields>
        </auc:Scenario>"

    element = REXML::Document.new(text)
    element = element.root.delete_namespace('auc').delete_namespace('xsi').delete_attribute('xsi:schemaLocation')
    scenarios.add_element(element)
  end

  # add measure packages
  packages = $Packages
  packages.each do |package|

    measure_ids = []
    package[:MeasureIDs].each do |measure_id|
      measure_ids << "<auc:MeasureID IDref=\"#{measure_id}\"/>"
    end
    measure_ids = measure_ids.join("\n")

    text = "<auc:Scenario #{xml_namespace}>
         <auc:ScenarioName>#{package[:ScenarioName]}</auc:ScenarioName>
          <auc:ScenarioType>
            <auc:PackageOfMeasures>
              <auc:ReferenceCase IDref=\"Baseline\"/>
              <auc:MeasureIDs>
                #{measure_ids}
              </auc:MeasureIDs>
            </auc:PackageOfMeasures>
          </auc:ScenarioType>
          <auc:LinkedPremises>
						<auc:Building>
							<auc:LinkedBuildingID IDref=\"#{building_id}\"/>
						</auc:Building>
					</auc:LinkedPremises>
					<auc:UserDefinedFields>
						<auc:UserDefinedField>
							<auc:FieldName>Recommendation Category</auc:FieldName>
							<auc:FieldValue>Potential Capital Recommendations</auc:FieldValue>
						</auc:UserDefinedField>
					</auc:UserDefinedFields>
        </auc:Scenario>"

    element = REXML::Document.new(text)
    element = element.root.delete_namespace('auc').delete_namespace('xsi').delete_attribute('xsi:schemaLocation')
    scenarios.add_element(element)
  end

  scenarios
end


def convert_building(feature, scenario_hash = nil, state_hash)

  building_id = get_building_id(feature)
  floor_area = get_floor_area(feature)
  source = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <auc:BuildingSync #{xml_namespace}>
  	<auc:Facilities>
  		<auc:Facility>
    		<auc:Sites>
    		</auc:Sites>
        <auc:Systems>
        </auc:Systems>
        <auc:Measures>
        </auc:Measures>
        <auc:Reports>
          <auc:Report>
          </auc:Report>
        </auc:Reports>
  		</auc:Facility>
	  </auc:Facilities>
  </auc:BuildingSync>
  "

  doc = REXML::Document.new(source)
  sites = doc.elements['*/*/*/auc:Sites']
  site = create_site(feature, scenario_hash, state_hash)
  sites.add_element(site)

  # add hvac system if heatingtype is present
  hvac_systems = create_system(feature)
  unless hvac_systems.nil?
    systems = doc.elements['*/*/*/auc:Systems']
    systems.add_element(hvac_systems)
  end

  # add measures
  measures = create_measures(feature)
  unless measures.nil?
    old_measures = doc.elements['*/*/*/auc:Measures']
    old_measures.parent.replace_child(old_measures, measures)
  end

  # add scenario (energystarscore, datastart, dataend?)
  scenarios = create_scenarios(feature)
  unless scenarios.nil?
    report = doc.elements['*/*/*/auc:Reports/auc:Report']
    report.add_element(scenarios)
  end

  doc

end

# output directory
outdir = "./#{WORKFLOW_OUTPUT_DIR}/#{GENERATE_DIR}"
FileUtils.mkdir_p(outdir) unless File.exist?(outdir)

# summary file
#summary_file = File.open(outdir + '/meta_summary.csv', 'w')
#summary_file.puts 'building_id,xml_filename,OccupancyClassification,BuildingName,FloorArea(ft2),YearBuilt,ClimateZone'

options = {headers: true, header_converters: :symbol}

if !occ_classification_file.nil?
  scenario_hash = json_to_hash(occ_classification_file)
  puts "Using scenario from file: #{occ_classification_file}"
  puts "Defines the following mapping: #{scenario_hash}"
else
  scenario_hash = {}
  a = "Office"
  scenario_hash[:Office] = a
  scenario_hash[:"Primary/Secondary Classroom"] = a
  scenario_hash[:"College Classroom"] = a
  scenario_hash[:Dormitory] = a
  scenario_hash[:"College Laboratory"] = a
  puts "No scenario file available.  Using the following mapping: #{scenario_hash}"
end

total_number_of_buildings = CSV.read(ARGV[0], :headers => true).count

CSV.foreach(ARGV[0], options).with_index do |feature, i|
  
  building_id = feature[:building_id]

  puts "Converting building #{i.next}/#{total_number_of_buildings}: building_id = #{building_id}  | bldgtype = #{feature[2]}  | location = #{feature[7]} #{feature[8]}"

  state_hash = json_to_hash(state_hash_file)

  begin
    doc = convert_building(feature, scenario_hash, state_hash)
    filename = File.join(outdir, "#{building_id}.xml")
    File.open(filename, 'w') do |file|
      doc.write(file)
    end
  rescue => e
    puts "Building #{building_id} not converted, #{e.message}"
    next
  end
end
