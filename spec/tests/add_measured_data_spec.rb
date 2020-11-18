
require 'rexml/document'
require 'csv'

require_relative './../../scripts/helper/csv_monthly_data.rb'
require_relative '../../scripts/constants'

ns = 'auc'
ts_file = "#{PROCESSED_DATA_DIR}/timeseriesdata.csv"
bsync_files = Dir["#{NAME_OF_OUTPUT_DIR}/#{ADD_MEASURED_DIR}/*.xml"]

class String
    def red; "\033[31m#{self}\033[0m" end
end

RSpec.describe 'EDV Experiment 1' do
    before(:all) do
        unless File.exist?(ts_file) && bsync_files.any?
            puts "ERROR - Can not find time_series data. Please refer to step 0-1.".red
            exit
        end
    end

    it 'should successfully compare time_series data to BSync hourly data' do

        # to randomly pick a file for validation
        f = bsync_files[rand(bsync_files.length)]

        ts_array = Array.new
        File.open(f, 'r') do |xml|
            doc = REXML::Document.new(xml)
            ts_elements = doc.elements["/#{ns}:BuildingSync/#{ns}:Facilities/#{ns}:Facility/#{ns}:Reports/#{ns}:Report/#{ns}:Scenarios/#{ns}:Scenario/#{ns}:TimeSeriesData"]
            ts_elements.each do |ts|
                next if ts.class != REXML::Element
                if ts.elements["#{ns}:IntervalFrequency"].text == 'Hour'
                    ts_array << ts.elements["#{ns}:IntervalReading"].text
                end

                expect(ts_array).not_to be_empty
            end
        end

        ts_data = CSV.read(ts_file, headers: true)
        ts_data.headers.each do |header|
            if header == File.basename(f, '.xml')
                ts_data_convert = []
                ts_data_convert = ts_data[header].map(&:to_f).map(&:to_s)

                expect(ts_data_convert).to eq ts_array
            end
        end
    end
end
