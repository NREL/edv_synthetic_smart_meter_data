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
  # first we want to convert the data from the csv file into building sync files
  # bundle exec rake generate_bdgp_xmls R:\NREL\the-building-data-genome-project\data\raw\meta_open.csv
  it 'should produce all building sync files' do
    # csv_file_path = File.join(root_dir, "bdgp_output/bdgp_summary.csv")
    # csv_file_path = File.join(File.expand_path('../../../.', File.dirname(__FILE__)), 'the-building-data-genome-project\data\raw\meta_open.csv')
    csv_file_path = File.join(File.expand_path('../../../.', File.dirname(__FILE__)), 'edv-experiment-1-files\bdgp_with_climatezones_epw.csv')
    puts "csv_file_path: #{csv_file_path}"

    result = run_script("bdgp_to_buildingsync", csv_file_path)

    puts "and the result is: #{result}"
    expect(result).to be true
  end

  # then we want to simulate the files
  it 'should translate buildingsync files to osm/osw and run simulations' do
    csv_file_path = File.join(File.expand_path('../../.', File.dirname(__FILE__)), 'spec/files/one_each_type.csv')
    #csv_file_path = File.join(File.expand_path('../../.', File.dirname(__FILE__)), 'spec/files/all.csv')
    #csv_file_path = File.join(File.expand_path('../../.', File.dirname(__FILE__)), 'spec/files/offices.csv')
    #csv_file_path = File.join(File.expand_path('../../.', File.dirname(__FILE__)), 'spec/files/prim_class.csv')
    #csv_file_path = File.join(File.expand_path('../../.', File.dirname(__FILE__)), 'spec/files/univ_class.csv')
    #csv_file_path = File.join(File.expand_path('../../.', File.dirname(__FILE__)), 'spec/files/univ_dorm.csv')
    #csv_file_path = File.join(File.expand_path('../../.', File.dirname(__FILE__)), 'spec/files/univ_lab.csv')
    puts "csv_file_path: #{csv_file_path}"

    result = run_script("process_all_bldg_sync_files_in_csv", csv_file_path)

    puts "and the result is: #{result}"
    expect(result).to be true
  end

  # then we want to combine results
  it 'should combine results into a csv' do
    csv_file_path = File.expand_path("../files/generation_script.csv", File.dirname(__FILE__))

    result = run_script("export_synthetic_data", csv_file_path)
    puts "and the result is: #{result}"
    expect(result).to be true
  end


  def run_script(script_file_name, argument1)
    root_dir = File.expand_path('../../.', File.dirname(__FILE__))
    script_path = File.join(root_dir, "scripts/#{script_file_name}.rb")
    puts "script_path: #{script_path}"
    runner = OpenStudio::Extension::Runner.new(root_dir)
    cli = OpenStudio.getOpenStudioCLI

    #cmd = "dir"
    cmd = "\"#{cli}\" --verbose --bundle '#{runner.gemfile_path}' --bundle_path '#{runner.bundle_install_path}' \"#{script_path}\" \"#{argument1}\""

    return runner.run_command(cmd, runner.get_clean_env)
  end
end