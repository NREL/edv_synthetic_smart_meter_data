# Make a list of unique weather files

require 'csv'

if ARGV[0].nil? || !File.exist?(ARGV[0])
  puts 'usage: bundle exec ruby make_weather_file_list.rb path/to/csv/file'
  puts ".csv files only"
  exit(1)
end

options = {headers:true, 
           header_converters: :symbol}

result = []
CSV.foreach(ARGV[0], options) do |feature|
	id = feature[:uid]
  datastart = feature[:datastart]
  dataend = feature[:dataend]
  city = feature[:city]
  state = feature[:state]
  
  puts datastart
  puts dataend
	yearstart = /^\d{1,2}\/\d{1,2}\/(\d{2})/.match(datastart)[1]
  yearend = /^\d{1,2}\/\d{1,2}\/(\d{2})/.match(dataend)[1]
  
  key = "20#{yearstart}-#{city}-#{state}"
  result << key
  
  key = "20#{yearend}-#{city}-#{state}"
  result << key  
end

puts result.uniq
puts result.uniq.size