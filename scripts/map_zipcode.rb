# match records and retrieve lat/lng
# use service to get zipcode

require 'csv'
require 'FileUtils'
require 'geocoder'

if ARGV[0].nil? || !File.exist?(ARGV[0]) || ARGV[1].nil? || !File.exist?(ARGV[1])
  puts 'usage: bundle exec ruby map_zipcode.rb /path/to/meta/with/zipcodes/csv /path/to/climate/lookup/csv'
  puts '.csv files only'
  exit(1)
end

# process 1st csv (read/write)
# process 2nd csv
# lookup each latlng in 2nd csv
# add to 1st csv's columns
# use geocoding service to get zipcodes
# save

new_csv_arr = []
headers = []
zips_arr = []

options = { headers: true, header_converters: :symbol }

CSV.foreach(ARGV[1], options) do |row|
  the_hash = {}
  the_hash[:zipcode] = row[:zip]
  the_hash[:climate_zone] = row[:zone_original]
  zips_arr << the_hash
end

puts 'importing climate zone lookup...'
puts "zips_arr size: #{zips_arr.size}"

puts 'processing zipcodes...'
CSV.foreach(ARGV[0], options) do |feature|
  headers = feature.headers
  id = feature[:uid]

  if /\A\d+\z/.match(feature[:zipcode])
    # this entry has a numeric zipcode
    # puts "found a zipcode: #{feature[:zipcode]}"
    matches = zips_arr.select {|row| row[:zipcode] === feature[:zipcode].gsub(/^0+/, '') }
    # puts "num matches: #{matches.size}"
    if matches.size > 0
      the_match = matches[0]
      puts "match: #{the_match}"
      feature[:climate_zone] = the_match[:climate_zone]
    else
      puts "no match for zipcode: #{feature[:zipcode]}"
    end
  end

  new_csv_arr << feature

end

headers << :climate_zone
# puts "HEADERS: #{headers}"

# write new array to file
# output directory
outdir = '../bdgp_output'
FileUtils.mkdir_p(outdir) unless File.exist?(outdir)

CSV.open(outdir + '/bdgp_withclimatezones.csv', 'w') do |csv|
  csv << headers
  new_csv_arr.each do |row|
    csv << row
  end
end


