require 'bundler/setup'

require 'json'
require 'rexml/document'
require 'rexml/xpath'
require 'date'
require 'openstudio/bldgs_calibration'
require 'openstudio/bldgs_calibration/calibrate_runner_single'
require_relative 'constants'

include REXML

=begin
input_json = {
	1 => {
    "osmPath"=>"/Users/llin/Documents/repo/edv-experiment-1/workflow_results/Simulation_Files/Panther_lodging_Hattie/in.osm", 
    "building_id"=>"Panther_lodging_Hattie", 
    "bldgType"=>"Commercial", 
    "electricity"=>"/Users/llin/Documents/repo/edv-experiment-1/scripts/../workflow_results/Calibration_Files/Panther_lodging_Hattie/output/true_electricity.json", 
    "annual_elec"=>408801.1205351751, 
    "gas"=>"/Users/llin/Documents/repo/edv-experiment-1/scripts/../workflow_results/Calibration_Files/Panther_lodging_Hattie/output/true_gas.json", 
    "annual_gas"=>0.0, 
    "hvac_sys_type"=>"Packaged system", 
    "epwPath"=>"/Users/llin/Documents/repo/edv-experiment-1/data/weather/temporary/temporary.epw", 
    "vintage"=>2019, 
    "cz"=>"cz3"
  }, 
  2 => {
    "osmPath"=>"/Users/llin/Documents/repo/edv-experiment-1/workflow_results/Simulation_Files/Panther_office_Patti/in.osm", 
    "building_id"=>"Panther_office_Patti", 
    "bldgType"=>"Commercial", 
    "electricity"=>"/Users/llin/Documents/repo/edv-experiment-1/scripts/../workflow_results/Calibration_Files/Panther_office_Patti/output/true_electricity.json", 
    "annual_elec"=>1620716.6529876138, 
    "gas"=>"/Users/llin/Documents/repo/edv-experiment-1/scripts/../workflow_results/Calibration_Files/Panther_office_Patti/output/true_gas.json", 
    "annual_gas"=>0.0, 
    "hvac_sys_type"=>"Packaged system", 
    "epwPath"=>"/Users/llin/Documents/repo/edv-experiment-1/data/weather/temporary/temporary.epw", 
    "vintage"=>2019, 
    "cz"=>"cz3"
  }, 
  3 => {
    "osmPath"=>"/Users/llin/Documents/repo/edv-experiment-1/workflow_results/Simulation_Files/Panther_education_Jerome/in.osm", 
    "building_id"=>"Panther_education_Jerome", 
    "bldgType"=>"Commercial", 
    "electricity"=>"/Users/llin/Documents/repo/edv-experiment-1/scripts/../workflow_results/Calibration_Files/Panther_education_Jerome/output/true_electricity.json", 
    "annual_elec"=>791610.8834447582, 
    "gas"=>"/Users/llin/Documents/repo/edv-experiment-1/scripts/../workflow_results/Calibration_Files/Panther_education_Jerome/output/true_gas.json", 
    "annual_gas"=>0.0, 
    "hvac_sys_type"=>"Packaged system", 
    "epwPath"=>"/Users/llin/Documents/repo/edv-experiment-1/data/weather/temporary/temporary.epw", 
    "vintage"=>2019, 
    "cz"=>"cz3"
  }
}
=end

class BuildingPortfolio

  def initialize

    @ns = 'auc'

    @calibration_output_dir = File.join(File.expand_path(File.dirname(__FILE__ )), "..", WORKFLOW_OUTPUT_DIR, CALIBRATION_OUTPUT_DIR)
    FileUtils.rm_rf(@calibration_output_dir) if File.exists?(@calibration_output_dir)
    sleep(0.1)
    Dir.mkdir(@calibration_output_dir)

    @portfolio = {}

    json_portfolio
  end

  def get_bldg_type(doc)

    building_type = doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Sites/#{@ns}:Site/#{@ns}:Buildings/#{@ns}:Building/#{@ns}:BuildingClassification"].text
    buidling_type = "office" if building_type.downcase == "commercial"

    building_type
  end

  def get_vintage(doc)
    vintage = ''
    scenarios = doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Reports/#{@ns}:Report/#{@ns}:Scenarios"]
    scenarios.each_element do |scenario|
      if scenario.attributes['ID'] == 'Baseline' && !scenario.elements["#{@ns}:TimeSeriesData"].nil?
        scenario.elements["#{@ns}:ResourceUses"].each_element do |resource|
          scenario.elements["#{@ns}:TimeSeriesData"].each_element do |ts|
            vintage = DateTime.parse(ts.elements["#{@ns}:StartTimestamp"].text).year
          end
        end
      end
    end
      vintage
  end

  def get_monthly_electricity(building, doc)
    monthly_electricity = {}
    monthly_electricity["data"] = []
    annual_electricity = 0

    scenarios = doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Reports/#{@ns}:Report/#{@ns}:Scenarios"]
    scenarios.each_element do |scenario|
      if scenario.attributes['ID'] == 'Baseline'
        if !scenario.elements["#{@ns}:TimeSeriesData"].nil?
          scenario.elements["#{@ns}:ResourceUses"].each_element do |resource|
            if resource.elements["#{@ns}:EnergyResource"].text == 'Electricity'
              scenario.elements["#{@ns}:TimeSeriesData"].each_element do |ts|
                if ts.attributes['ID'].include?(resource.attributes['ID'])
                  monthly_electricity["data"].push({"accounts": 1,
                                                    "from": ts.elements["#{@ns}:StartTimestamp"].text.insert(-1, 'Z'),
                                                    "peak": 0,
                                                    "to": ts.elements["#{@ns}:EndTimestamp"].text.insert(-1, 'Z'),
                                                    "tot_kwh": ts.elements["#{@ns}:IntervalReading"].text.to_f})
                  annual_electricity += ts.elements["#{@ns}:IntervalReading"].text.to_f
                end
              end
            end
          end
        end
      end
    end

    output_dir = File.join(@calibration_output_dir, building, 'output')
    FileUtils.mkdir_p(output_dir) unless File.exists?(output_dir)
    path = File.join(output_dir, 'true_electricity.json')
    File.open(path, 'w') do |f|
      f.write(JSON.pretty_generate(monthly_electricity))
    end

    [path, annual_electricity]
  end

  def get_monthly_gas(building, doc)
    monthly_gas = {}
    monthly_gas["data"] = []
    annual_gas = 0

    scenarios = doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Reports/#{@ns}:Report/#{@ns}:Scenarios"]
    scenarios.each_element do |scenario|
      if scenario.attributes['ID'] == 'Baseline'
        if !scenario.elements["#{@ns}:TimeSeriesData"].nil?
          scenario.elements["#{@ns}:ResourceUses"].each_element do |resource|
            if resource.elements["#{@ns}:EnergyResource"].text == 'Natural gas'
              scenario.elements["#{@ns}:TimeSeriesData"].each_element do |ts|
                if ts.attributes['ID'].include?(resource.attributes['ID'])
                  monthly_gas["data"].push({"accounts": 1,
                                            "from": ts.elements["#{@ns}:StartTimestamp"].text.insert(-1, 'Z'),
                                            "peak": 0,
                                            "to": ts.elements["#{@ns}:EndTimestamp"].text.insert(-1, 'Z'),
                                            "tot_therms": ts.elements["#{@ns}:IntervalReading"].text.to_f + 1}) # TODO: fix gas consumption from BuidlingSync
                  annual_gas += ts.elements["#{@ns}:IntervalReading"].text.to_f
                end
              end
            end
          end
        end
      end
    end

    output_dir = File.join(@calibration_output_dir, building, 'output')
    FileUtils.mkdir_p(output_dir) unless File.exists?(output_dir)
    path = File.join(output_dir, 'true_gas.json')
    File.open(path, 'w') do |f|
      f.write(JSON.pretty_generate(monthly_gas))
    end

    [path, annual_gas]
  end

  def json_single(path)
    json_single = {}

    Dir.glob(File.join(path, '/*.xml')).each do |xml|
      building = File.basename(xml, '.xml')

      json_single["osmPath"] = File.expand_path(File.join(path, 'in.osm'))

      doc = REXML::Document.new(File.open(xml, 'r+'))
      json_single["building_id"] = building
      json_single["bldgType"] = "office" # get_bldg_type(doc)
      json_single["electricity"], json_single["annual_elec"] = get_monthly_electricity(building, doc)
      json_single["gas"], json_single["annual_gas"] = get_monthly_gas(building, doc)

      if json_single["gas"].nil?
        json_single["hvac_sys_type"] = "Centralized system"
      elsif json_single["electricity"].nil?
        json_single["hvac_sys_type"] = "Heat pump"
      else
        json_single["hvac_sys_type"] = "Packaged system"
      end

      json_single["epwPath"] = File.expand_path(File.join(File.dirname(__FILE__), '..', DEFAULT_WEATHERDATA_DIR, 'temporary.epw'))
      json_single["vintage"] = get_vintage(doc)
    end
    json_single["cz"] = "cz6"

    json_single
  end

  def json_portfolio
    sim_dir = File.join(WORKFLOW_OUTPUT_DIR, SIM_FILES_DIR)
    puts "Missing Simulation Files" if !File.exist?(sim_dir)

    i = 1
    Dir.entries(sim_dir).each do |f|
      osm_path = File.join(sim_dir, f)
      if File.exist?(File.join(osm_path, 'in.osm'))
        @portfolio[i] = json_single(osm_path)
        i = i + 1
      end
    end
  end

  attr_reader :portfolio, :calibration_output_dir
end

class Calibration
  def calibration(portfolio, calibration_output_dir)
    # calibrate single building
    puts "Run single building calibration:"
    runner_single = OpenStudio::BldgsCalibration::CalibrateRunnerSingle.new
    max_runs = 30

    (1..portfolio.length).each do |i|
      next if portfolio[i]["calibration_level"] == "portfolio"
      portfolio[i]["bldgType"] = 'office' if portfolio[i]["bldgType"].downcase == 'commercial'
      calibration_path = File.join(calibration_output_dir, portfolio[i]["building_id"], 'output')
      runner_single.run(portfolio[i]["osmPath"], 
                        portfolio[i]["bldgType"], 
                        portfolio[i]["hvac_sys_type"], 
                        portfolio[i]["electricity"], 
                        portfolio[i]["gas"], 
                        portfolio[i]["epwPath"], 
                        calibration_path,
                        max_runs, 
                        portfolio[i]["vintage"])

      File.open(File.join(calibration_path, "calibration_report.json"), 'w') do |f|
       f.write(JSON.pretty_generate(runner_single.cali_report))
      end
    end
=begin
    # calibration portfolio
    puts "Run portfolio building calibration:"
    calibration_path = File.join(calibration_output_dir, 'portfolio_calibration')
    runner_portfolio = OpenStudio::BldgsCalibration::CalibrateRunnerPortfolio.new(calibration_path)
    runner_portfolio.portfolio_calibrate(portfolio)
=end
  end
end

building_portfolio = BuildingPortfolio.new
building_calibration = Calibration.new
building_calibration.calibration(building_portfolio.portfolio, building_portfolio.calibration_output_dir)
