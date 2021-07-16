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
        "baseline_osm_path": ,
        "bldg_type": ,
        "electricity": {"data": [
                            {"accounts": 1,
                            "from": "#{start_time_stamp}",
                            "peak": 0,
                            "to": "#{end_time_stamp}",
                            "tot_kwh": ,},
                            ...
                        ]},
        "gas": {},
        "hvac_sys_type": ,
        "epw_path": , # epw path,
        "year": ,
    },

    2 => {
        "baseline_osm_path": ,
        "bldg_type": ,
        "electricity": {"data": [
                            {"accounts": 1,
                            "from": "#{start_time_stamp}",
                            "peak": 0,
                            "to": "#{end_time_stamp}",
                            "tot_kwh": ,},
                            ...
                        ]},
        "gas": {},
        "hvac_sys_type": ,
        "epw_path": , # epw path,
        "year": ,
    },

    3 => {
        "baseline_osm_path": ,
        "bldg_type": ,
        "electricity": {"data": [
                            {"accounts": 1,
                            "from": "#{start_time_stamp}",
                            "peak": 0,
                            "to": "#{end_time_stamp}",
                            "tot_kwh": ,},
                            ...
                        ]},
        "gas": {},
        "hvac_sys_type": ,
        "epw_path": , # epw path,
        "year": ,
    },
}
=end

class BuildingPortfolio

    def initialize

        @ns = 'auc'
        @portfolio = {}

        json_portfolio
    end

    def get_bldg_type(doc)

        doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Sites/#{@ns}:Site/#{@ns}:Buildings/#{@ns}:Building/#{@ns}:BuildingClassification"].text

    end

    def get_year(doc)
        year = ''
        scenarios = doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Reports/#{@ns}:Report/#{@ns}:Scenarios"]
        scenarios.each_element do |scenario|
            if scenario.attributes['ID'] == 'Baseline' && !scenario.elements["#{@ns}:TimeSeriesData"].nil?
                scenario.elements["#{@ns}:ResourceUses"].each_element do |resource|
                    scenario.elements["#{@ns}:TimeSeriesData"].each_element do |ts|
                        year = DateTime.parse(ts.elements["#{@ns}:StartTimestamp"].text).year
                    end
                end
            end
        end
        
        year
    end

    def get_monthly_electricity(doc)

        # return monthly electricity data
        # TODO: 6/28. Need to generate data for all months
        monthly_electricity = {}
        monthly_electricity["data"] = []

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
                                end
                            end
                        end
                    end
                end
            end
        end

        # write to a electricity json file
        calibration_output_dir = File.join(WORKFLOW_OUTPUT_DIR, CALIBRATION_OUTPUT_DIR)
        FileUtils.rm_rf(calibration_output_dir) if File.exists?(calibration_output_dir)
        sleep(0.1)
        Dir.mkdir(calibration_output_dir)

        path = File.expand_path(File.join(File.dirname(__FILE__), '..', calibration_output_dir, 'true_electricity.json'))
        File.open(path, 'w') do |f|
            f.write(JSON.pretty_generate(monthly_electricity))
        end
        puts "elec absolute path: #{path}"
        path
    end

    def get_monthly_gas(doc)

        # return monthly natural gas data
        # TODO: 6/28. Need to generate data for all months
        monthly_gas = {}
        monthly_gas["data"] = []

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
                                                            "tot_therms": ts.elements["#{@ns}:IntervalReading"].text.to_f})
                                end
                            end
                        end
                    end
                end
            end
        end

        # write to a gas json file
        calibration_output_dir = File.join(WORKFLOW_OUTPUT_DIR, CALIBRATION_OUTPUT_DIR)

        path = File.expand_path(File.join(File.dirname(__FILE__), '..', calibration_output_dir, 'true_gas.json'))
        File.open(path, 'w') do |f|
            f.write(JSON.pretty_generate(monthly_gas))
        end
        puts "gas absolute path: #{path}"
        path
    end

    def json_single(path)
        json_single = {}
        Dir.glob(File.join(path, '/*.xml')).each do |xml|
            json_single["baseline_osm_path"] = File.expand_path(File.join(path, 'in.osm'))
            puts "baseline_osm_path: #{json_single["baseline_osm_path"]}"
            doc = REXML::Document.new(File.open(xml, 'r+'))
            json_single["bldg_type"] = get_bldg_type(doc)
            json_single["electricity"] = get_monthly_electricity(doc)
            json_single["gas"] = get_monthly_gas(doc)

            if json_single["gas"].nil?
                json_single["hvac_sys_type"] = "Centralized system"
            elsif json_single["electricity"].nil?
                json_single["hvac_sys_type"] = "Heat pump"
            else
                json_single["hvac_sys_type"] = "Packaged system"
            end

            json_single["epw_path"] = File.expand_path(File.join(File.dirname(__FILE__), '..', DEFAULT_WEATHERDATA_DIR, 'temporary.epw'))
            puts "json_single epw absolute path: #{json_single["epw_path"]}"
            json_single["year"] = get_year(doc)
        end

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

    attr_reader :portfolio
end

class Calibration
    def calibration(portfolio)

        # calibrate single building
        runner_single = OpenStudio::BldgsCalibration::CalibrateRunnerSingle.new
        max_runs = 30

        calibration_output_dir = File.join(WORKFLOW_OUTPUT_DIR, CALIBRATION_OUTPUT_DIR)
        (1..portfolio.length).each do |i|
            portfolio[i]["bldg_type"] = 'office' if portfolio[i]["bldg_type"].downcase == 'commercial'
            runner_single.run(portfolio[i]["baseline_osm_path"], 
                              portfolio[i]["bldg_type"], 
                              portfolio[i]["hvac_sys_type"], 
                              portfolio[i]["electricity"], 
                              portfolio[i]["gas"], 
                              portfolio[i]["epw_path"], 
                              calibration_output_dir, 
                              max_runs, 
                              portfolio[i]["year"])
        end

        File.open(File.join(calibration_output_dir, 'calibration_report.json'), 'w') do |f|
            f.write(JSON.pretty_generate(runner_single.cali_report))
        end
    end
end


building_portfolio = BuildingPortfolio.new
building_calibration = Calibration.new
building_calibration.calibration(building_portfolio.portfolio)
