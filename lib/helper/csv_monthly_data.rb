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
    @day = nil
    @month = nil
    @year = nil
    @start_time_stamp = nil
    @end_time_stamp = nil
    @annual_native_total = nil
    @annual_total = nil
    @peak_value_array = nil
    @hourly_values = {}
    @csv_hourly = {}
    @total_value = {}
    @total_native_value = {}
    @start_time_hourly = {}
    @peak_values = {}
  end

  def update_day(day_value)
    @day = day_value
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

  def update_start_time_hourly(start_time)
    @start_time_hourly = [] if @start_time_hourly.nil?
    @start_time_hourly[@year] = [] if @start_time_hourly[@year].nil?
    @start_time_hourly[@year][@month] = [] if @start_time_hourly[@year][@month].nil?
    @start_time_hourly[@year][@month][@day] = [] if @start_time_hourly[@year][@month][@day].nil?
    @start_time_hourly[@year][@month][@day].push (start_time.gsub('/', '-'))
  end

  def get_hourly_start_timestamp
    @start_time_stamp = @start_time_hourly[@year][@month]
  end

  def update_start_time(start_time)
    # BDGP/BDGP2 raw start timestamp -> XSD date/time data types
    @start_time_stamp = start_time.gsub('/', '-')
  end

  def update_end_time(end_time)
    # BDGP/BDGP2 raw end timestamp -> XSD date/time data types
    @end_time_stamp = end_time.gsub('/', '-') + ":00"
  end

  def update_total_values(value, counter)
    csv_value = value.to_f
    if @total_value[counter].nil? || @total_native_value[counter].nil?
      @total_native_value[counter] = csv_value
      @total_value[counter] = csv_value * 3.41214
    else
      @total_native_value[counter] += csv_value
      @total_value[counter] += csv_value * 3.41214
    end
  end

  def get_total_values
    return @total_value
  end

  def get_native_total_values
    return @total_native_value
  end

  def update_hourly_values(value, counter)
    csv_hourly_value = value.to_f
    @csv_hourly = [] if @csv_hourly.nil?
    @csv_hourly[@year] = [] if @csv_hourly[@year].nil?
    @csv_hourly[@year][@month] = [] if @csv_hourly[@year][@month].nil?
    @csv_hourly[@year][@month][counter] = [] if @csv_hourly[@year][@month][counter].nil?
    @csv_hourly[@year][@month][counter].push csv_hourly_value
  end

  def update_peak_values(value, counter)
    @peak_values = [] if @peak_values.nil?
    @peak_values[@year] = [] if @peak_values[@year].nil?
    if @peak_values[@year][counter].nil?
      @peak_values[@year][counter] = value
    else
      @peak_values[@year][counter].push value
    end
  end

  def get_hourly_values
    @hourly_values = @csv_hourly[@year][@month]
  end

  def get_peak_value_array
    @peak_value_array = @peak_values[@year]
  end

  def get_summary
    total = 0
    @total_value.each do |item, value|
      total += value.to_f
    end
    total
  end
  
  def initialize_native_value
    @total_native_value = {}
  end

  def initialize_total_value
    @total_value = {}
  end

  def update_fuel(fuel_type)
    @fuel = fuel_type
  end

  attr_reader :day, :month, :year, :start_time_stamp, :end_time_stamp, :fuel, :hourly_values, :kbtu_total, :kwh_total, :total_native_value, :total_value, :peak_value_array
end
