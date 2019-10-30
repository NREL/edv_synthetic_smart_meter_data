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
    calculated_eui = MetricsCalc.calculate_eui_value(energy_consumption, floor_area)
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

    calculated_cvrmse = MetricsCalc.calculate_cvrmse(measured_data, measured_data)
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

    calculated_cvrmse = MetricsCalc.calculate_cvrmse(measured_data, simulated_data)

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

    calculated_nmbe = MetricsCalc.calculate_nmbe(measured_data, simulated_data)

    ysum = measured_value_kWh_1 + measured_value_kWh_2
    sum_error = (measured_value_kWh_1 - simulated_value_kWh_1) + (measured_value_kWh_2 - simulated_value_kWh_2)
    n = 2
    ybar = ysum / n
    nmbe = 100 * (sum_error/(n-1)) / ybar
    puts "nmbe: #{nmbe}"
    expect(calculated_nmbe).to eq nmbe
  end
end
