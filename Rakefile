desc 'generate BDGP BuildingSync XMLs'
task :generate_bdgp_xmls do

  ARGV.each { |a| task a.to_sym do ; end }

  if ARGV[1]

  	# ARGV[1] should be a path to a CSV file
  	ruby "scripts/bdgp_to_buildingsync.rb #{ARGV[1]}"

  else
  	# need path to csv file
  	puts "Error - No CSV file specified"
  	puts "Usage: rake generate_bdgp_xmls path/to/csv/file"
  
  end

end

