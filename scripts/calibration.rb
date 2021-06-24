
require 'json'
require 'rexml/document'
require 'rexml/xpath'
require 'date'

require_relative 'constants'

include REXML

=begin
output_json = {
    1 => {
        "osmPath": ,
        "bldgType": ,
        "monthlyElec": [],
        "monthlyGas": [],
        "mainSpaceHeatingFeul": ,
        "weather": , # epw path,
    },

    2 => {
        "osmPath": ,
        "bldgType": ,
        "monthlyElec": [],
        "monthlyGas": [],
        "mainSpaceHeatingFeul": ,
        "weather": , # epw path,
    },

    3 => {
        "osmPath": ,
        "bldgType": ,
        "monthlyElec": [],
        "monthlyGas": [],
        "mainSpaceHeatingFeul": ,
        "weather": , # epw path,
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
        # TODO - JK: baseline?
        # return monthly electricity data
        monthly_elec = []

        scenarios = doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Reports/#{@ns}:Report/#{@ns}:Scenarios"]
        scenarios.each do |scenario|
            if scenario.class == REXML::Element && scenario.attributes['ID'] == 'Baseline'
                if !scenario.elements["#{@ns}:TimeSeriesData"].nil?
                    scenario.elements["#{@ns}:ResourceUses"].each do |resource|
                        if resource.class == REXML::Element
                            if resource.elements["#{@ns}:EnergyResource"].text == 'Electricity'
                                scenario.elements["#{@ns}:TimeSeriesData"].each do |ts|
                                    if ts.class == REXML::Element && ts.attributes['ID'].include?(resource.attributes['ID'])
                                        # ts.elements["#{@ns}:StartTimestamp"].text
                                        # ts.elements["#{@ns}:EndTimestamp"].text
                                        # ts.elements["#{@ns}:IntervalReading"].text
                                        # @year = DateTime.parse(ts.elements["#{@ns}:IntervalReading"].text).year
                                        # @month = DateTime.parse(ts.elements["#{@ns}:IntervalReading"].text).month
                                        # @day = DateTime.parse(ts.elements["#{@ns}:IntervalReading"].text).day
                                        monthly_elec.push(ts.elements["#{@ns}:IntervalReading"].text.to_f)
                                    end
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
        monthly_gas = []
        scenarios = doc.elements["/#{@ns}:BuildingSync/#{@ns}:Facilities/#{@ns}:Facility/#{@ns}:Reports/#{@ns}:Report/#{@ns}:Scenarios"]
        scenarios.each do |scenario|
            if scenario.class == REXML::Element && scenario.attributes['ID'] == 'Baseline'
                if !scenario.elements["#{@ns}:TimeSeriesData"].nil?
                    scenario.elements["#{@ns}:ResourceUses"].each do |resource|
                        if resource.class == REXML::Element
                            if resource.elements["#{@ns}:EnergyResource"].text == 'Natural gas'
                                scenario.elements["#{@ns}:TimeSeriesData"].each do |ts|
                                    if ts.class == REXML::Element && ts.attributes['ID'].include?(resource.attributes['ID'])
                                        monthly_gas.push(ts.elements["#{@ns}:IntervalReading"].text.to_f)
                                    end
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
            json_single["osm_path"] = path

            doc = REXML::Document.new(File.open(xml, 'r+'))
            json_single["bldg_type"] = get_bldg_type(doc)
            json_single["monthlyElec"] = get_monthly_electricity(doc)
            json_single["monthlyGas"] = get_monthly_gas(doc)
            json_single["weather"] = DEFAULT_WEATHERDATA_DIR

            if json_single["monthlyGas"].all? {|e| e.to_f == 0}
                json_single["mainSpaceHeatingFeul"] = "Electricity"
            else
                json_single["mainSpaceHeatingFeul"] = "Natural gas"
            end
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
    def calibration(portfolio, run_portfolio=false)
        if run_portfolio
            puts portfolio
            # portfolioCalibrate(f)
        else
            (1..portfolio.length).each do |i|
                puts "#{portfolio[i]}"
                # singleCalibrate(f[i])
            end
        end
    end
end

building_portfolio = BuildingPortfolio.new
building_portfolio.portfolio
building_calibration = Calibration.new
building_calibration.calibration(building_portfolio.portfolio, true)
