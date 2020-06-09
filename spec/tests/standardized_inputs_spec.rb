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
require 'csv'
require_relative './../../scripts/helper/standardize_input.rb'

RSpec.describe 'Standardized inputs' do
  # first we want to check labels converted are matching with pre-defined standardized labels
  # bundle exec rake standardize_metadata_and_timeseriesdata
  it 'should correctly convert raw labels in the metadata file to standardized labels' do
    
    #standardized labels
    std_labels = ['building_id',
                  'xml_filename',
                  'primary_building_type',
                  'floor_area_sqft',
                  'vintage',
                  'climate_zone',
                  'zipcode',
                  'city',
                  'us_state',
                  'longitude',
                  'latitude',
                  'number_of_stories',
                  'number_of_occupants',
                  'fuel_type_heating',
                  'energystar_score',
                  'measurement_start_date',
                  'measurement_end_date',
                  'weather_file_name_epw',
                  'weather_file_name_ddy']
    
    # read test data headers:
    # csv = CSV.open('../files/meta_open_epw_ddy.csv', headers: true)
    # puts csv.read.headers

    f = StdInput.new
    option = {headers: true,
              header_converters: :symbol}
    f.copy_columns('../files/meta_open_epw_ddy.csv', option)
    
    # compare before and after files: meta_open_epw_ddy.csv vs meta_open_epw_ddy_standardized.csv
    expect(CSV.read('../files/meta_open_epw_ddy.csv').size).to eq (CSV.read('meta_open_epw_ddy_standardized.csv').size)
  end

end
