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

require 'fileutils'
require 'parallel'
require 'open3'
require 'csv'

NUM_OF_FILES = 10
NAME_OF_OUTPUT_DIR = "Test_output"
# NOTE: you need to run these test in this order, since files are dependent on earlier test output

RSpec.describe 'EDV Experiment 1' do
  # first we want to convert the data from the csv file into building sync files
  # bundle exec rake generate_bdgp_xmls R:\NREL\the-building-data-genome-project\data\raw\meta_open.csv
  it 'should produce all 10 sync files based on a modified csv file with only 10 buildings ' do
    csv_file_path = File.join(File.expand_path('../.', File.dirname(__FILE__)), 'files/meta_open_epw_ddy.csv')
    puts "csv_file_path: #{csv_file_path}"

    result = run_script("bdgp_to_buildingsync", csv_file_path)

    puts "and the result is: #{result}"
    expect(result).to be true

    outdir = File.join(File.expand_path('../../.', File.dirname(__FILE__)), "#{NAME_OF_OUTPUT_DIR}/Bldg_Sync_Files")

    iNewFileCount = Dir.glob("#{outdir}/*.xml").count
    puts "Found #{iNewFileCount} files in #{outdir} (should be #{NUM_OF_FILES}!)"
    expect(iNewFileCount).to eq NUM_OF_FILES
  end

  it 'should add measured data to the 10 bldg sync files' do
    csv_file_path = File.join(File.expand_path('../.', File.dirname(__FILE__)), 'files/temp_open_utc.csv')
    puts "csv_file_path: #{csv_file_path}"
    bldg_sync_file_path = File.join(File.expand_path('../../.', File.dirname(__FILE__)), "#{NAME_OF_OUTPUT_DIR}/Bldg_Sync_Files")
    puts "bldg_sync_file_path: #{bldg_sync_file_path}"

    result = run_script("add_measured_data", csv_file_path, bldg_sync_file_path)

    puts "and the result is: #{result}"
    expect(result).to be true

    outdir = File.join(File.expand_path('../../.', File.dirname(__FILE__)), "#{NAME_OF_OUTPUT_DIR}/#{ADD_MEASURED_DIR}")

    iNewFileCount = Dir.glob("#{outdir}/*.xml").count
    puts "Found #{iNewFileCount} files in #{outdir} (should be #{NUM_OF_FILES}!)"
    expect(iNewFileCount).to eq NUM_OF_FILES
  end

  it 'should generate a csv files to drive the simulation script' do
    csv_file_path = File.join(File.expand_path('../.', File.dirname(__FILE__)), 'files/meta_open_epw_ddy.csv')
    puts "csv_file_path: #{csv_file_path}"
    bldg_sync_file_path = File.join(File.expand_path('../../.', File.dirname(__FILE__)), "#{NAME_OF_OUTPUT_DIR}/Bldg_Sync_Files")
    puts "bldg_sync_file_path: #{bldg_sync_file_path}"
    weather_file_path = File.join(File.expand_path('../.', File.dirname(__FILE__)), 'weather')
    puts "weather_file_path: #{weather_file_path}"

    result = run_script("generate_csv_containing_all_bldgs", bldg_sync_file_path, 'ASHRAE90.1', csv_file_path, weather_file_path)

    puts "and the result is: #{result}"
    expect(result).to be true

    outdir = File.join(File.expand_path('../../.', File.dirname(__FILE__)), "#{NAME_OF_OUTPUT_DIR}/Control_Files")

    iNewFileCount = Dir.glob("#{outdir}/all.csv").count
    puts "Found #{iNewFileCount} files in #{outdir} (should be 1)"
    expect(iNewFileCount).to eq 1
  end

  # then we want to simulate the files
  it 'should translate buildingsync files to osm/osw and run simulations' do
    csv_file_path =  File.join(File.expand_path('../../.', File.dirname(__FILE__)), "#{NAME_OF_OUTPUT_DIR}/Control_Files/all.csv")
    puts "csv_file_path: #{csv_file_path}"

    result = run_script("process_all_bldg_sync_files_in_csv", csv_file_path)

    puts "and the result is: #{result}"
    expect(result).to be true

    outdir = File.join(File.expand_path('../../.', File.dirname(__FILE__)), "#{NAME_OF_OUTPUT_DIR}/Simulation_Files")

    iNewFileCount = Dir.glob("#{outdir}/*.xml").count
    puts "Found #{iNewFileCount} files in #{outdir} (should be #{NUM_OF_FILES})"
    expect(iNewFileCount).to eq NUM_OF_FILES

    osm_files = []
    osm_sr_files = []
    Dir.glob("#{outdir}/**/**/in.osm") {
        |osm| osm_files << osm
        puts "OSM file #{osm}"
    }
    Dir.glob("#{outdir}/**/SR/in.osm") { |osm| osm_sr_files << osm }
    Dir.glob("#{outdir}/**/SR/run/in.osm") { |osm| osm_sr_files << osm }

    puts "found #{osm_files.size} osm files and #{osm_sr_files.size} SR osm files"
    # we compare the counts, by also considering the two potential osm files in the SR directory
    expect(osm_files.size - osm_sr_files.size).to eq NUM_OF_FILES * 7

    result_Json_files = []
    Dir.glob("#{outdir}/**/**/results.json") { |json| result_Json_files << json }

    # we compare the counts, by also considering the two potential sql files in the SR directory
    expect(result_Json_files.size).to eq NUM_OF_FILES * 7
  end


  # then we want to calculate the metrics
  it 'should calculate the metrics' do
    sim_file_path =  File.join(File.expand_path('../../.', File.dirname(__FILE__)), 'Test_output/Simulation_Files/')
    puts "sim_file_path: #{sim_file_path}"

    result = run_script("calculate_metrics", 'R:/NREL/edv-experiment-1/Test_output/Simulation_Files')

    puts "and the result is: #{result}"
    expect(result).to be true

    outdir = File.join(File.expand_path('../../.', File.dirname(__FILE__)), 'Test_output/Simulation_Files')

    iNewFileCount = Dir.glob("#{outdir}/*.xml").count
    puts "Found #{iNewFileCount} files in #{outdir} (should be #{NUM_OF_FILES})"
    expect(iNewFileCount).to eq NUM_OF_FILES
  end

  # then we want to combine results
  it 'should combine results into a csv' do
    csv_file_path = File.expand_path("../files/generation_script.csv", File.dirname(__FILE__))

    puts "csv_file_path: #{csv_file_path}"
    result = run_script("export_synthetic_data", csv_file_path)
    expect(result).to be true

    outdir = File.join(File.expand_path('../../.', File.dirname(__FILE__)), 'Test_output/Simulation_Files')

    iNewFileCount = Dir.glob("#{outdir}/*/*.csv").count
    puts "Found #{iNewFileCount} files in #{outdir} (should be #{NUM_OF_FILES})"
    expect(iNewFileCount).to eq NUM_OF_FILES
  end

  def run_script(script_file_name, argument1, argument2 = nil, argument3 = nil, argument4 = nil)
    root_dir = File.expand_path('../../.', File.dirname(__FILE__))
    script_path = File.join(root_dir, "scripts/#{script_file_name}.rb")
    puts "script_path: #{script_path}"
    runner = OpenStudio::Extension::Runner.new(root_dir)
    cli = OpenStudio.getOpenStudioCLI

    #cmd = "dir"
    if argument2.nil?
      cmd = "\"#{cli}\" --verbose --bundle '#{runner.gemfile_path}' --bundle_path '#{runner.bundle_install_path}' \"#{script_path}\" \"#{argument1}\""
    elsif argument3.nil?
      cmd = "\"#{cli}\" --verbose --bundle '#{runner.gemfile_path}' --bundle_path '#{runner.bundle_install_path}' \"#{script_path}\" \"#{argument1}\" \"#{argument2}\""
    elsif argument4.nil?
      cmd = "\"#{cli}\" --verbose --bundle '#{runner.gemfile_path}' --bundle_path '#{runner.bundle_install_path}' \"#{script_path}\" \"#{argument1}\" \"#{argument2}\" \"#{argument3}\""
    else
      cmd = "\"#{cli}\" --verbose --bundle '#{runner.gemfile_path}' --bundle_path '#{runner.bundle_install_path}' \"#{script_path}\" \"#{argument1}\" \"#{argument2}\" \"#{argument3}\" \"#{argument4}\""
    end
    return runner.run_command(cmd, runner.get_clean_env)
  end
end