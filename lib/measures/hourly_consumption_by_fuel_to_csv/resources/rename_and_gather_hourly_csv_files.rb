require 'fileutils'
require 'openstudio'

# notes:
# this script isn't used by the measure, I put it here for refenrece. It can be used to scrape the datapoint directories and copy a renamed csv file to a common location.
# eventually this could be done on the server as part ot PAT run

# source and target directories
project_directory = "project_dir"
target_directory = "hourly_csv_files"

# loop through resoruce files
results_directories = Dir.glob("#{project_directory}/LocalResults/*")
results_directories.each do |results_directory|

	idf_building_name = nil

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{results_directory}/out.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Ruleset::OSRunner.new(osw)

    # 2.x methods (currently setup for measure display name but snake_case arg names)
    runner.workflow.workflowSteps.each do |step|
      if step.to_MeasureStep.is_initialized
        measure_step = step.to_MeasureStep.get

        measure_name = measure_step.measureDirName
        if measure_step.name.is_initialized
          measure_name = measure_step.name.get # this is instance name in PAT
        end
        if measure_step.result.is_initialized
          result = measure_step.result.get
          result.stepValues.each do |arg|
            next if not arg.name == "idf_building_name"
            value = arg.valueAsVariant.to_s
            idf_building_name = value
            puts "#{measure_name}: #{arg.name} = #{value}"
          end
        else
          #puts "No result for #{measure_name}"
        end
      else
        #puts "This step is not a measure"
      end
    end

	# copy and rename file
	orig_file = "#{File.dirname(__FILE__)}/#{results_directory}/hourly_consumption_by_fuel_to_csv_report.csv"
	copy_file = "#{target_directory}/#{idf_building_name}.csv"
	if File.file?(orig_file)
		puts "Creating #{copy_file}"
		FileUtils.cp(orig_file, copy_file)
	end

end
