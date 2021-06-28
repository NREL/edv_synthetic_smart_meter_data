
require 'json'
require 'rexml/document'
require 'rexml/xpath'
require 'date'

require_relative 'constants'

include REXML

=begin
output_json = {
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
    },
}
=end

class BuildingPortfolio

    def initialize

        @ns = 'auc'
        # @day = nil
        # @month = nil
        # @year = nil
        # @osm_path = nil
        # @bldg_type = nil
        # @feul = nil
        # @monthly = {}
        # @json_single = {}
        @portfolio = {}

        json_portfolio
    end

    def get_bldg_type(doc)

        doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Sites/#{@ns}:Site/#{@ns}:Buildings/#{@ns}:Building/#{@ns}:BuildingClassification"].text

    end

    def get_monthly_electricity(doc)

        # return monthly electricity data
        monthly_elec = {}
        monthly_elec["data"] = []

        scenarios = doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Reports/#{@ns}:Report/#{@ns}:Scenarios"]
        scenarios.each_element do |scenario|
            if scenario.attributes['ID'] == 'Baseline'
                if !scenario.elements["#{@ns}:TimeSeriesData"].nil?
                    scenario.elements["#{@ns}:ResourceUses"].each_element do |resource|
                        if resource.elements["#{@ns}:EnergyResource"].text == 'Electricity'
                            scenario.elements["#{@ns}:TimeSeriesData"].each_element do |ts|
                                if ts.attributes['ID'].include?(resource.attributes['ID'])
                                    monthly_elec["data"].push({"accounts": 1,
                                                                "from": ts.elements["#{@ns}:StartTimestamp"].text,
                                                                "peak": 0,
                                                                "to": ts.elements["#{@ns}:EndTimestamp"].text,
                                                                "tot_kwh": ts.elements["#{@ns}:IntervalReading"].text.to_f})
                                end
                            end
                        end
                    end
                end
            end
        end

        monthly_elec
    end

    def get_monthly_gas(doc)
        # return monthly natural gas data
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
                                                            "from": ts.elements["#{@ns}:StartTimestamp"].text,
                                                            "peak": 0,
                                                            "to": ts.elements["#{@ns}:EndTimestamp"].text,
                                                            "tot_kwh": ts.elements["#{@ns}:IntervalReading"].text.to_f})
                                end
                            end
                        end
                    end
                end
            end
        end

        monthly_gas
    end

    def json_single(path)
        json_single = {}
        Dir.glob(File.join(path, '/*.xml')).each do |xml|
            json_single["baseline_osm_path"] = File.join(path, 'in.osm')

            doc = REXML::Document.new(File.open(xml, 'r+'))
            json_single["bldg_type"] = get_bldg_type(doc)
            json_single["electricity"] = get_monthly_electricity(doc)
            json_single["gas"] = get_monthly_gas(doc)

            if json_single["gas"]["data"].all? {|e| e["tot_therms"].to_f == 0}
                json_single["hvac_sys_type"] = "Centralized system"
            elsif json_single["electricity"]["data"].all? {|e| e["tot_kwh"].to_f == 0}
                json_single["hvac_sys_type"] = "Heat pump"
            else
                json_single["hvac_sys_type"] = "Packaged system"
            end

            json_single["epw_path"] = File.join(DEFAULT_WEATHERDATA_DIR, 'temporary.epw')
        end

        json_single
    end

    def json_portfolio
        sim_dir = File.join(NAME_OF_OUTPUT_DIR, SIM_FILES_DIR)
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
        load '../../openstudio-bldgs-calibration-gem/lib/openstudio/bldgs_calibration/calibrate_runner_single.rb'
        (1..portfolio.length).each do |i|
            puts "single calibration: #{portfolio[i]}"
        end
    end
end

building_portfolio = BuildingPortfolio.new
building_portfolio.portfolio
building_calibration = Calibration.new
building_calibration.calibration(building_portfolio.portfolio)
