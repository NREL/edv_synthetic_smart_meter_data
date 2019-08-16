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
require 'openstudio-occupant-variability'

RSpec.describe 'EDV Experiment 1' do
  it 'should run test file 1 with occupancy measure' do
    result = test_occupancy_mesure('test1.xml', 'temporary.epw')
    expect(result).to be true
  end

  #it 'should run test file without any other measures with occupancy measure' do
  #  result = test_occupancy_mesure('test1_no_measures.xml', 'temporary.epw')
  #  expect(result).to be true
  #end

  def test_occupancy_mesure(xml_name, epw_name = nil)
    root_dir = File.join(File.dirname(__FILE__), '../../')
    xml_path = File.join(root_dir, "spec/files/#{xml_name}")
    epw_path = File.join(root_dir, "scripts/#{epw_name}")
    out_path = File.expand_path("../../spec/output/#{File.basename(xml_path, File.extname(xml_path))}/", File.dirname(__FILE__))

    if File.exist?(out_path)
      FileUtils.rm_rf(out_path)
    end
    FileUtils.mkdir_p(out_path)

    translator = BuildingSync::Translator.new(xml_path, out_path, epw_path, 'ASHRAE90.1')
    translator.write_osm(true)

    occupant_variability_instance = OpenStudio::OccupantVariability::Extension.new
    translator.add_measure_path(occupant_variability_instance.measures_dir)
    args_hash = {}
    i = 1
    space_types = translator.get_space_types
    space_types.each do |space_type|
      current_spaces = space_type.spaces
      next if not current_spaces.size > 0
      current_spaces.each do |space|
        args_hash["Space_#{i}_#{space.name}"] = 'Office Type 1'
        i += 1
      end
    end
    translator.insert_energyplus_measure('Occupancy_Simulator', 0, args_hash)

    translator.write_osws

    osws = Dir.glob("#{out_path}/**/in.osw") - Dir.glob("#{out_path}/SR/in.osw")

    runner = OpenStudio::Extension::Runner.new(root_dir)
    runner.run_osws(osws, 4)

    puts "after runner"
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
