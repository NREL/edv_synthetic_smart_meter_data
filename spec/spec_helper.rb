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

# try to load configuration, use defaults if doesn't exist
begin
  require_relative '../config'
rescue LoadError, StandardError
  module BuildingSync
    # location of openstudio CLI
    OPENSTUDIO_EXE = 'openstudio'.freeze

    # one or more measure paths
    OPENSTUDIO_MEASURES = [].freeze

    # one or more file paths
    OPENSTUDIO_FILES = [].freeze
  end
end

# for all testing
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'bundler/setup'
require 'buildingsync/translator'

def run_script(script_name)
  root_dir = File.join(File.dirname(__FILE__), '../')
  script_path = File.join(root_dir, "scripts/#{script_name}")
  runner = OpenStudio::Extension::Runner.new(root_dir)
  cli = OpenStudio.getOpenStudioCLI
  cmd = "\"#{cli}\" --verbose --bundle '#{runner.gemfile_path}' --bundle_path '#{runner.bundle_install_path}' \"#{script_path}\" "

  runner.run_command(cmd, runner.get_clean_env)
end

def process_all_bldg_sync_files_in_csv(csv_file_name)
  root_dir = File.expand_path('../.', File.dirname(__FILE__))
  puts "root_dir: #{root_dir}"

  csv_file_path = File.join(root_dir, "/spec/files/#{csv_file_name}")
  puts "csv_file_path: #{csv_file_path}"

  output_path = File.join(root_dir, "/spec/output/")
  Dir.mkdir output_path if !Dir.exists? output_path

  log_file_path = File.join(root_dir, "/spec/output/#{File.basename(csv_file_name)}.log")
  puts "log_file_path: #{log_file_path}"
  csv_table = CSV.read(csv_file_path)
  log = File.open(log_file_path, 'w')
  csv_table.each do |xml_file, standard, epw_file|
    puts "processing xml_file: #{xml_file} - standard: #{standard} - epw_file: #{epw_file}"
    log.puts("processing xml_file: #{xml_file} - standard: #{standard} - epw_file: #{epw_file}")

    xml_file_path = File.join(root_dir, "/bdgp_output/#{xml_file}")
    out_path = File.join(root_dir,"/spec/output/#{File.basename(xml_file, File.extname(xml_file))}/")
    epw_file_path = File.join(root_dir, "/script/#{epw_file}/")
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

def run_simulate_bdgp_xml_path(xml_path, standard = "ASHRAE90.1", epw_name = nil)

  root_dir = File.join(File.dirname(__FILE__), '../')
  script_path = File.join(root_dir, 'scripts/simulate_bdgp_xml.rb')
  epw_path = File.join(root_dir, "spec/files/#{epw_name}")

  runner = OpenStudio::Extension::Runner.new(root_dir)
  cli = OpenStudio.getOpenStudioCLI

  #cmd = "dir"
  cmd = "\"#{cli}\" --verbose --bundle '#{runner.gemfile_path}' --bundle_path '#{runner.bundle_install_path}' \"#{script_path}\" \"#{xml_path}\" \"#{standard}\" \"#{epw_name}\""

  return runner.run_command(cmd, runner.get_clean_env)

end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
