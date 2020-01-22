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

class MonthlyData

  def initialize
    @month = nil
    @year = nil
    @start_time_stamp = nil
    @end_time_stamp = nil
    @total_value = {}
  end

  def update_month(month_value)
    @month = month_value
  end

  def update_year(year_value)
    @year = year_value
  end

  def add_start_date_string(start_date)
    @start_time_stamp = start_date
    split = start_date.split('-')
    @year = split.first
    @month = split[1]
  end

  def update_start_time(start_time)
    @start_time_stamp = start_time
  end

  def update_end_time(end_time)
    @end_time_stamp = end_time
  end

  def update_values(value, counter)
    csv_value = value.to_f
    if @total_value[counter].nil?
      # converting from kWh to kBtu (multiply by 3.412)
      @total_value[counter] = csv_value * 3.412
    else
      # converting from kWh to kBtu (multiply by 3.412)
      @total_value[counter] += csv_value * 3.412
    end
  end

  def get_values
    return @total_value
  end

  def get_sum
    total = 0
    @total_value.each do |item, value|
      total += value.to_f
    end
    return total
  end

  attr_reader :month, :year, :start_time_stamp, :end_time_stamp
end
