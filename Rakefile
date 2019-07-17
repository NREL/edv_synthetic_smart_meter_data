require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc 'generate BDGP BuildingSync XMLs'
task :generate_bdgp_xmls do

  ARGV.each { |a| task a.to_sym do ; end }

  if ARGV[1]

  	# ARGV[1] should be a path to a CSV file
  	ruby "scripts/bdgp_to_buildingsync.rb #{ARGV[1]}"

  else
  	# need path to csv file
  	puts "Error - No CSV file specified"
  	puts "Usage: bundle exec rake generate_bdgp_xmls path/to/csv/file"
  
  end

end

desc 'simulate a BDGP BuildingSync XML'
task :simulate_bdgp_xml do

  ARGV.each { |a| task a.to_sym do ; end }

  if ARGV[1]

  	# ARGV[1] should be a path to a BDGP BuildingSync XML file
  	ruby "scripts/simulate_bdgp_xml.rb #{ARGV[1]}"

  else
  	# need path to csv file
  	puts "Error - No BDGP BuildingSync XML file specified"
  	puts "Usage: bundle exec rake simulate_bdgp_xml path/to/xml/file"
  
  end
end

desc 'simulate a batch of BDGP BuildingSync XML files'
task :simulate_batch_bdgp_xml do

  ARGV.each { |a| task a.to_sym do ; end }

  if ARGV[1]

    # ARGV[1] should be a path to a BDGP BuildingSync XML file
    ruby "scripts/process_all_bldg_sync_files_in_csv.rb #{ARGV[1]}"

  else
    # need path to csv file
    puts "Error - No CSV file specified that would contain the BldgSync files to be process in this batch"
    puts "Usage: bundle exec rake process_all_bldg_sync_files_in_csv path/to/csv/file"

  end
end

desc 'append lat/lng/zipcode information to CSV'
task :geocode_meta_csv do

  ARGV.each { |a| task a.to_sym do ; end }

  if ARGV[1] && ARGV[2]

  	# ARGV[1] should be a path to a CSV file
  	ruby "scripts/map_latlng.rb #{ARGV[1]} #{ARGV[2]}"

  else
  	# need path to csv file
  	puts "Error - No CSV files specified"
  	puts "Usage: rake geocode_meta_csv /path/to/meta/csv /path/to/latlng/csv"
  
  end
end

desc 'lookup and append climate_zone information to CSV'
task :lookup_climate_zone_csv do

  ARGV.each { |a| task a.to_sym do ; end }

  if ARGV[1] && ARGV[2]

  	# ARGV[1] should be a path to a CSV file
  	ruby "scripts/map_zipcode.rb #{ARGV[1]} #{ARGV[2]}"

  else
  	# need path to csv file
  	puts "Error - No CSV files specified"
  	puts "Usage: rake lookup_climate_zone_csv /path/to/meta/with/zipcodes/csv /path/to/climate/lookup/csv"
  
  end
end

task default: :spec
