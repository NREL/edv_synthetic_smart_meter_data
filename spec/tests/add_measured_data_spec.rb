
require 'rexml/document'
require 'csv'

require_relative './../../scripts/helper/csv_monthly_data.rb'
require_relative '../../scripts/constants'

=begin
NAME_OF_OUTPUT_DIR # /workflow_results
PROCESSED_DATA_DIR # /data/processed
ADD_MEASURED_DIR # /Add_Measured_Data_files
=end

ns = 'auc'
f_timeseries = "#{PROCESSED_DATA_DIR}/timeseriesdata.csv"
bsync_files = Dir["#{NAME_OF_OUTPUT_DIR}/#{ADD_MEASURED_DIR}/*.xml"]

class String
    def red;            "\033[31m#{self}\033[0m" end
end

RSpec.describe 'EDV Experiment 1' do
    before(:all) do
        unless File.exist?(f_timeseries) && bsync_files.any?
            puts "ERROR - Can not find time_series data. Please refer to step 0-1.".red
            exit
        end
    end

    it 'should successfully compare time_series data to BSync hourly data' do
        # randomly pick a file for validation
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
            end
        end

        ts_data = CSV.read(f_timeseries, headers: true)
        ts_data.headers.each do |header|
            if header == File.basename(f, '.xml')
                ts_data[header].each_with_index do |v, i|
                    if v != ts_array[i]
                        # TODO: to compare arrays, not elements
                        # puts "False: #{v} - #{ts_array[i]}"
                        expect(v.to_f.to_s).to eq ts_array[i]
                    end
                end
            end
        end
    end
end
