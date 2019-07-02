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

task default: :spec
