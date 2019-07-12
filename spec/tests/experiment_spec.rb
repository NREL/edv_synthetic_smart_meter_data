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

RSpec.describe 'EDV Experiment 1' do

  it 'should run test file 1' do
    result = run_simulate_bdgp_xml('test1.xml')
    expect(result).to be true
  end

  it 'should translate all buildingsync files contained in csv file to osm baselines ' do
    process_all_bldg_sync_files_in_csv("all.csv")
  end

  it 'should translate one buildingsync file per type contained in csv file to osm baselines' do
    process_all_bldg_sync_files_in_csv("one_each_type.csv")
  end

  it 'should generate the csv file containing all xml files' do
    csv_file_path = File.expand_path('../../csv_file/all.csv', File.dirname(__FILE__))
    root_dir = File.join(File.dirname(__FILE__), '../../')
    puts root_dir
    xml_files = []
    Dir.glob("#{root_dir}/*/*.xml") { |xml| xml_files << xml }
    csv = File.open(csv_file_path, 'w')
    xml_files.each do |xml_file|
      csv.puts("#{File.basename(xml_file)},ASHRAE90.1,temporary.epw")
    end
    csv.close
  end

  def process_all_bldg_sync_files_in_csv(csv_file_name)
    root_dir = File.expand_path(File.dirname(__FILE__), '../../')
    csv_file_path = File.expand_path("../../csv_file/#{csv_file_name}", File.dirname(__FILE__))
    log_file_path = File.expand_path("../../csv_file/#{File.basename(csv_file_name)}.log", File.dirname(__FILE__))
    csv_table = CSV.read(csv_file_path)
    log = File.open(log_file_path, 'w')
    csv_table.each do |xml_file, standard, epw_file|
      puts "processing xml_file: #{xml_file} - standard: #{standard} - epw_file: #{epw_file}"
      log.puts("processing xml_file: #{xml_file} - standard: #{standard} - epw_file: #{epw_file}")

      xml_file_path = File.expand_path("../../bdgp_output/#{xml_file}/", File.dirname(__FILE__))
      out_path = File.expand_path("../../output/#{File.basename(xml_file, File.extname(xml_file))}/", File.dirname(__FILE__))
      epw_file_path = File.expand_path("../../script/#{epw_file}/", File.dirname(__FILE__))
      result = run_simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path)

      puts "...completed: #{result} and osm file exist: #{File.exist?("#{out_path}/in.osm")}"
      log.puts("...completed: #{result} and osm file exist: #{File.exist?("#{out_path}/in.osm")}")

      output_dirs = []
      Dir.glob("#{out_path}/**/") { |output_dir| output_dirs << output_dir }
      output_dirs.each do |output_dir|
        if !output_dir.include? "/SR"
          if output_dir != out_path
            sql_file = File.expand_path(output_dir, "/eplusout.sql")
            if !File.exist?(sql_file)
              log.puts("...ERROR: #{sql_file} does not exist, simulation was unsucessful}")
            end
          end
        end
      end
    end
    log.close
  end

  def run_simulate_bdgp_xml(xml_name, epw_name = nil)

    root_dir = File.join(File.dirname(__FILE__), '../../')
    script_path = File.join(root_dir, 'scripts/simulate_bdgp_xml.rb')
    xml_path = File.join(root_dir, "spec/files/#{xml_name}")
    epw_path = File.join(root_dir, "spec/files/#{epw_name}")

    runner = OpenStudio::Extension::Runner.new(root_dir)
    cli = OpenStudio.getOpenStudioCLI

    #cmd = "dir"
    cmd = "\"#{cli}\" --verbose --bundle '#{runner.gemfile_path}' --bundle_path '#{runner.bundle_install_path}' \"#{script_path}\" \"#{xml_path}\""

    return runner.run_command(cmd, runner.get_clean_env)

  end

  def run_simulate_bdgp_xml_path(xml_path, standard = "ASHRAE90.1", epw_name = nil)

    root_dir = File.join(File.dirname(__FILE__), '../../')
    script_path = File.join(root_dir, 'scripts/simulate_bdgp_xml.rb')
    epw_path = File.join(root_dir, "spec/files/#{epw_name}")

    runner = OpenStudio::Extension::Runner.new(root_dir)
    cli = OpenStudio.getOpenStudioCLI

    #cmd = "dir"
    cmd = "\"#{cli}\" --verbose --bundle '#{runner.gemfile_path}' --bundle_path '#{runner.bundle_install_path}' \"#{script_path}\" \"#{xml_path}\" \"#{standard}\" \"#{epw_name}\""

    return runner.run_command(cmd, runner.get_clean_env)

  end

end
