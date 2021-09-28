# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC.
# BuildingSync(R), Copyright (c) 2015-2019, Alliance for Sustainable Energy, LLC.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************
require_relative './../spec_helper'
require_relative './../../scripts/helper/metrics_calculation.rb'
require_relative './../../scripts/helper/csv_monthly_data.rb'

RSpec.describe 'EDV Experiment 1' do
  # first we want to convert the data from the csv file into building sync files
  # bundle exec rake generate_bdgp_xmls R:\NREL\the-building-data-genome-project\data\raw\meta_open.csv
  it 'should correctly calculate eui' do
    energy_consumption = 10000
    floor_area = 200
    calculated_eui = Metrics.calculate_eui_value(energy_consumption, floor_area)
    expect(calculated_eui).to eq energy_consumption / floor_area
  end

  it 'should correctly calculate cvrmse to be 0 if measured and simulated data are the same' do
    measured_data = MonthlyData.new
    measured_data.update_start_time("00:00")
    measured_data.update_year(2019)
    measured_data.update_month(1)
    measured_data.update_end_time("00:00")
    value_btu = 2000
    value_kWh = value_btu / 3.142
    measured_data.update_values(value_kWh, 1)
    measured_data.update_values(value_kWh, 2)

    calculated_cvrmse = Metrics.calculate_cvrmse(measured_data, measured_data)
    expect(calculated_cvrmse).to eq 0
  end

  it 'should correctly calculate cvrmse' do
    measured_data = MonthlyData.new
    measured_data.update_start_time("00:00")
    measured_data.update_year(2019)
    measured_data.update_month(1)
    measured_data.update_end_time("00:00")

    simulated_data = measured_data
    value_btu = 2000
    measured_value_kWh_1 = value_btu / 3.142
    measured_value_kWh_2 = measured_value_kWh_1
    measured_data.update_values(measured_value_kWh_1, 1)
    measured_data.update_values(measured_value_kWh_2, 2)

    simulated_value_kWh_1 = measured_value_kWh_1 / 2
    simulated_value_kWh_2 = simulated_value_kWh_1
    simulated_data = MonthlyData.new
    simulated_data.update_start_time("00:00")
    simulated_data.update_year(2019)
    simulated_data.update_month(1)
    simulated_data.update_end_time("00:00")
    simulated_data.update_values(simulated_value_kWh_1, 1)
    simulated_data.update_values(simulated_value_kWh_2, 2)

    calculated_cvrmse = Metrics.calculate_cvrmse(measured_data, simulated_data)

    ysum = measured_value_kWh_1 + measured_value_kWh_2
    squared_error = (measured_value_kWh_1 - simulated_value_kWh_1)**2 + (measured_value_kWh_2 - simulated_value_kWh_2)**2
    n = 2
    ybar = ysum / n
    rmse = 100 * (squared_error/(n-1))**0.5 / ybar
    puts "rmse: #{rmse}"
    expect(calculated_cvrmse).to eq rmse
  end

  it 'should correctly calculate nmbe' do
    measured_data = MonthlyData.new
    measured_data.update_start_time("00:00")
    measured_data.update_year(2019)
    measured_data.update_month(1)
    measured_data.update_end_time("00:00")

    simulated_data = measured_data
    value_btu = 2000
    measured_value_kWh_1 = value_btu / 3.142
    measured_value_kWh_2 = measured_value_kWh_1
    measured_data.update_values(measured_value_kWh_1, 1)
    measured_data.update_values(measured_value_kWh_2, 2)

    simulated_value_kWh_1 = measured_value_kWh_1 / 2
    simulated_value_kWh_2 = simulated_value_kWh_1
    simulated_data = MonthlyData.new
    simulated_data.update_start_time("00:00")
    simulated_data.update_year(2019)
    simulated_data.update_month(1)
    simulated_data.update_end_time("00:00")
    simulated_data.update_values(simulated_value_kWh_1, 1)
    simulated_data.update_values(simulated_value_kWh_2, 2)

    calculated_nmbe = Metrics.calculate_nmbe(measured_data, simulated_data)

    ysum = measured_value_kWh_1 + measured_value_kWh_2
    sum_error = (measured_value_kWh_1 - simulated_value_kWh_1) + (measured_value_kWh_2 - simulated_value_kWh_2)
    n = 2
    ybar = ysum / n
    nmbe = 100 * (sum_error/(n-1)) / ybar
    puts "nmbe: #{nmbe}"
    expect(calculated_nmbe).to eq nmbe
  end

  it 'correctly add an sum up measured data into BldgSync xml and be the same value as original measured data' do
    ns = 'auc'

    measured_file_path = File.join(File.expand_path('../.', File.dirname(__FILE__)), 'files/temp_open_utc.csv')
    # read the column headers so we now how many files we need to process
    column_headers = CSV.read(measured_file_path, headers: true).headers
    # read in the CSV file into an array
    parsed = CSV.read(measured_file_path, headers: true)

    successful = 0
    # find the right columns
    for i in 1..column_headers.count-1
 #     if column_headers[i] == 'UnivLab_Andre'
        puts "processing file: #{column_headers[i]}"
        measured_total_csv_data = 0
        parsed[column_headers[i]].each do |value|
 #         puts "value: #{value}"
          measured_total_csv_data += value.to_f
        end
        measured_total_csv_data = measured_total_csv_data * 3.142

        measured_total_xml_data = 0
        bldg_sync_office_caleb = File.join(File.expand_path('../../.', File.dirname(__FILE__)), "#{WORKFLOW_OUTPUT_DIR}/#{MEASURED_DATA_DIR}/#{column_headers[i]}.xml")
        doc = nil
        File.open(bldg_sync_office_caleb, 'r') do |bldg_sync_office_caleb|
          doc = REXML::Document.new(bldg_sync_office_caleb)
          # first we get the measured scenario
          scenario_elements = doc.elements["/#{ns}:BuildingSync/#{ns}:Facilities/#{ns}:Facility/#{ns}:Reports/#{ns}:Report/#{ns}:Scenarios"]
          # for the first pass we just look for the measured scenario
          counter = 0
          scenario_elements.each do |scenario_element|
            if scenario_element.attributes['ID'] == 'Measured'
              scenario_element.elements["#{ns}:TimeSeriesData"].each do |time_series|
                counter += 1
       #         puts "monthly value #{counter}: #{time_series.elements["#{ns}:IntervalReading"].text.to_f}"
                measured_total_xml_data += time_series.elements["#{ns}:IntervalReading"].text.to_f
              end
            end
          end
        end

        if (measured_total_csv_data - measured_total_xml_data).abs > 0.0001
          puts "FAILED:::: measured_total_csv_data: #{measured_total_csv_data} versus measured_total_xml_data: #{measured_total_xml_data}"
        else
          successful += 1
          puts "measured_total_csv_data: #{measured_total_csv_data} versus measured_total_xml_data: #{measured_total_xml_data}"
        end
  #    end
    end
    expect(successful).to be 10
  end
end
