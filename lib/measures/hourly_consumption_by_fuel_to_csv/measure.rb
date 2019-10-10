# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

#start the measure
class HourlyConsumptionByFuelToCSV < OpenStudio::Ruleset::ReportingUserScript

  # human readable name
  def name
    return "Hourly Consumption By Fuel to CSV"
  end

  # human readable description
  def description
    return "Exported hourly consumption by fuel to a CSV file."
  end

  # human readable description of modeling approach
  def modeler_description
    return "This doesn't produce an HTML file, rather it creates a CSV file for use in post processing."
  end

  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # this measure does not require any user arguments, return an empty list

    return args
  end 
  
  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(), user_arguments)
      return result
    end

    request_elec = OpenStudio::IdfObject.load("Output:Meter,Electricity:Facility,Hourly;").get
    request_gas = OpenStudio::IdfObject.load("Output:Meter,Gas:Facility,Hourly;").get
    request_clg = OpenStudio::IdfObject.load("Output:Meter,DistrictCooling:Facility,Hourly;").get
    request_htg = OpenStudio::IdfObject.load("Output:Meter,DistrictHeating:Facility,Hourly;").get

    result << request_elec
    result << request_gas
    result << request_clg
    result << request_htg

    return result
  end
  
  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # todo - not using this code to loop through fuel types
    OpenStudio::EndUseFuelType.getValues.each do |fuel_type|
      fuel_type = OpenStudio::EndUseFuelType.new(fuel_type).valueDescription
    end

    # get the last model workspace and sql file (not currently using model)
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    workspace = runner.lastEnergyPlusWorkspace
    if workspace.empty?
      runner.registerError("Cannot find last workspace.")
      return false
    else
    end
    workspace = workspace.get

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    # get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
          break
        end
      end
    end

    # only try to get the annual timeseries if an annual simulation was run
    if ! ann_env_pd.nil?

      # get desired variable
      key_value =  ""
      time_step = "Hourly"

      # gather time series data
      time_series_data = {}
      if sqlFile.timeSeries(ann_env_pd, time_step, "Electricity:Facility", key_value).is_initialized
        time_series_data['Electricity'] = sqlFile.timeSeries(ann_env_pd, time_step, "Electricity:Facility", key_value).get.values
      end
      if sqlFile.timeSeries(ann_env_pd, time_step, "Gas:Facility", key_value).is_initialized
        time_series_data['Gas'] = sqlFile.timeSeries(ann_env_pd, time_step, "Gas:Facility", key_value).get.values
      end
      if sqlFile.timeSeries(ann_env_pd, time_step, "DistrictCooling:Facility", key_value).is_initialized
        time_series_data['DistrictCooling'] = sqlFile.timeSeries(ann_env_pd, time_step, "DistrictCooling:Facility", key_value).get.values
      end
      if sqlFile.timeSeries(ann_env_pd, time_step, "DistrictHeating:Facility", key_value).is_initialized
        time_series_data['DistrictHeating'] = sqlFile.timeSeries(ann_env_pd, time_step, "DistrictHeating:Facility", key_value).get.values
      end

      # get min number of hours for fules that had time series
      min_hours_data = nil
      time_series_data.each do |k,v|
        if min_hours_data.nil?
          min_hours_data = v.size
        elsif v.size < min_hours_data
          min_hours_data = v.size
        end
      end

      # setup csv
      require 'csv'

      # path for reports
      building = workspace.getObjectsByType("Building".to_IddObjectType)
      building_name = building.first.getString(0)
      runner.registerInitialCondition("Generating hourly load report for #{building_name}.")
      report_path = "./report.csv" # has to be report.csv to be added to reports folder "./report_#{building_name}.csv"
      FileUtils.rm_f(report_path) if File.exist?(report_path)
      csv = CSV.open(report_path, 'w')
      # populate header row for CSV
      csv << ['Electricity','Natural Gas','District Cooling','District Heating']

      # write to csv
      min_hours_data.times do |i|

        # setup data for row
        if time_series_data.has_key?('Electricity')
          col_a = time_series_data['Electricity'][i]
        else
          col_a = nil
        end
        if time_series_data.has_key?('Gas')
          col_b = time_series_data['Gas'][i]
        else
          col_b = nil
        end
        if time_series_data.has_key?('DistrictCooling')
          col_c = time_series_data['DistrictCooling'][i]
        else
          col_c = nil
        end
        if time_series_data.has_key?('DistrictHeating')
          col_d = time_series_data['DistrictHeating'][i]
        else
          col_d = nil
        end

        # populate row
        csv << [col_a,col_b,col_c,col_d]

      end

    else
      runner.registerWarning("No annual environment period found.")
    end

    # close the sql file
    sqlFile.close()
    runner.registerFinalCondition("Finished Writing file to #{report_path}")

    return true
 
  end

end

# register the measure to be used by the application
HourlyConsumptionByFuelToCSV.new.registerWithApplication
