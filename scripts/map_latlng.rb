# match records and retrieve lat/lng
# use service to get zipcode

require 'csv'
require 'FileUtils'
require 'geocoder'

if ARGV[0].nil? || !File.exist?(ARGV[0]) || ARGV[1].nil? || !File.exist?(ARGV[1]) 
  puts 'usage: bundle exec ruby map_latlng.rb /path/to/meta/csv /path/to/latlng/csv'
  puts ".csv files only"
  exit(1)
end

# process 1st csv (read/write)
# process 2nd csv
# lookup each latlng in 2nd csv
# add to 1st csv's columns 
# use geocoding service to get zipcodes (rate limited 1000/hr)
# save

new_csv_arr = []
headers = []
lat_lng_arr = []

options = {headers:true, header_converters: :symbol}

CSV.foreach(ARGV[1], options) do |row|
	the_hash = {}
	the_hash[:uid] = row[:uid]
	the_hash[:lat] = row[:lat]
	the_hash[:lng] = row[:lng]
	lat_lng_arr << the_hash
end

puts "lat_lng_arr size: #{lat_lng_arr.size}"

CSV.foreach(ARGV[0], options) do |feature|
	headers = feature.headers
	id = feature[:uid]

	matches = lat_lng_arr.select {|row| row[:uid] === id }
	# puts "num matches: #{matches.size}"
	if matches.size > 0
		the_match = matches[0]
		feature[:lat] = the_match[:lat]
		feature[:lng] = the_match[:lng]

		# geocoder
		res = Geocoder.search("#{feature[:lat]}, #{feature[:lng]}")
		puts "zip: #{res.first.postal_code}"
		feature[:city] = res.first.city
		feature[:state] = res.first.state

	end

	new_csv_arr << feature
	
end

headers << :lat
headers << :lng
headers << :city
headers << :state
headers << :zipcode
puts "HEADERS: #{headers}"

# write new array to file
# output directory
outdir = '../bdgp_output'
FileUtils.mkdir_p(outdir) unless File.exist?(outdir)

CSV.open(outdir + "/bdgp_withlatlng.csv", "w") do |csv|
  csv << headers
  new_csv_arr.each do |row|
  	csv << row
  end
end


