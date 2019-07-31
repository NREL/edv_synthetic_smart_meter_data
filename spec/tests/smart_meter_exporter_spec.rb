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
require 'json'
require 'csv'

RSpec.describe 'EDV Experiment 1' do
  it 'first test of the csv generator' do
    json_file_path = File.expand_path("../files/generation_script.json", File.dirname(__FILE__))

    json_content = File.read(json_file_path)
    parsed = JSON.parse(json_content) # returns a hash

    building_sync_file_path = File.dirname(json_file_path) + "/" + parsed["building_sync_file"]
    epw_path = File.join(File.dirname(building_sync_file_path), "../../scripts/#{parsed["epw_file"]}")
    out_path = File.expand_path("../../spec/output/#{File.basename(building_sync_file_path, File.extname(building_sync_file_path))}/", File.dirname(__FILE__))

    # first we process the building_sync_file
    run_simulations(building_sync_file_path, out_path, epw_path) if Dir.glob("#{out_path}/**/**/report.csv").count == 0

    csvs = Hash.new
    Dir.glob("#{out_path}/**/**/report.csv").each do |csv|
      measure_name = csv.split(File::Separator)[-3]
      puts "adding entry to hash: #{measure_name} -- #{csv}"
      csvs[measure_name] = csv
    end

    current_scenario = Hash.new
    date_array = parsed["start_date"].split('/')
    start_date = Time.local(date_array[2],date_array[0],date_array[1])
    puts "start_date: #{start_date}"
    date_array = parsed["end_date"].split('/')
    end_date = Time.local(date_array[2],date_array[0],date_array[1])
    current_scenario["scenario_name"] = "Baseline"
    current_path = csvs[current_scenario["scenario_name"]]
    puts "csvs: #{csvs}"
    file = File.open current_path
    values = file.to_a
    puts "values[0]: #{values[0]}"
    active_scenarios = parsed["active_scenarios"]
    scenario_counter = 0
    next_scenario = active_scenarios[scenario_counter]
    # initialize the headers
    csv_array = [["Test", 1], ["Test", 2]]
    CSV.open(out_path + "/file.csv", "wb") do |csv|
      csv << ["", "Building-Smart-Meter-Export"]
      csv << ["", "Realization Name: #{parsed["realization_name"]}"]
      csv << ["", "Export Date: #{Time.now.strftime("%d/%m/%Y %H:%M")}"]
      csv << [""]
      csv << ["", "Electricity Used - whole building [J]"]
      csv << ["Timestamp", "Building Id #{parsed["building_id"]}"]
      counter = 0
      8760.times do
        current_date = start_date + (counter) * 3600
        if next_scenario.nil?
          date_array =  parsed["end_date"].split('/')
        else
          date_array = next_scenario["active_after"].split('/')
        end
        if current_date < Time.local(date_array[2],date_array[0],date_array[1]) + 3600 * 23 + 60 * 59 + 59
          current_values = values[counter + 1]
        elsif active_scenarios.count > scenario_counter
          puts "sencario count: #{active_scenarios.count} scenario:_counter: #{scenario_counter}"
          current_scenario = active_scenarios[scenario_counter]
          current_path = csvs[current_scenario["scenario_name"]]
          file.close
          puts "current_scenario: #{current_scenario} current_path: #{current_path}"
          file = File.open current_path
          values = file.to_a
          current_values = values[counter + 1]
          scenario_counter += 1
          next_scenario = active_scenarios[scenario_counter]
        end
        if(current_values.nil?)
          csv << [current_date.strftime("%d/%m/%Y %H:%M"), "", current_scenario["scenario_name"]]
        else
          csv << [current_date.strftime("%d/%m/%Y %H:%M"), current_values.split(',')[0], current_scenario["scenario_name"]]
        end

        counter+=1
      end
      file.close
    end
  end

  def run_simulations(xml_path, out_path, epw_path)
    root_dir = File.expand_path("../../../", xml_path)
    translator = BuildingSync::Translator.new(xml_path, out_path, epw_path, 'ASHRAE90.1')
    translator.add_measure_path("#{root_dir}/lib/measures")
    translator.insert_reporting_measure('hourly_consumption_by_fuel_to_csv', 0)
    translator.write_osm(true)
    translator.write_osws

    osws = Dir.glob("#{out_path}/**/in.osw") - Dir.glob("#{out_path}/SR/*.osw")

    runner = OpenStudio::Extension::Runner.new(out_path)
    runner.run_osws(osws, 4)

    successful = true
    osws.each do |osw|
      sql_file = osw.gsub('in.osw', 'eplusout.sql')
      puts "Simulation not completed successfully for file: #{osw}" if !File.exist?(sql_file)
      successful = false  if !File.exist?(sql_file)
      expect(File.exist?(sql_file)).to be true
    end
    return successful
  end
end
