# Run a BuildingSync XML file to generate synthetic smart meter data

require 'openstudio/extension'
require 'openstudio/model_articulation/os_lib_model_generation_bricr'
require 'buildingsync'
require 'buildingsync/translator'
require 'openstudio/occupant_variability'

if ARGV[0].nil?
  puts 'usage: bundle exec ruby simulate_bdgp_xml.rb path/to/xml/file standard_to_be_used (optional) epw_file_path (optional)'
  puts "must provide at least a .xml file"
  exit(1)
end

if !File.exist?(ARGV[0])
  puts 'usage: bundle exec ruby simulate_bdgp_xml.rb path/to/xml/file standard_to_be_used (optional) epw_file_path (optional)'
  puts "XML file does not exist: #{ARGV[0]}"
  exit(1)
end

xml_path = ARGV[0]

standard_to_be_used = 'CaliforniaTitle24'
if !ARGV[1].nil? && (ARGV[1] == 'CaliforniaTitle24' || ARGV[1] == 'ASHRAE90.1')
  standard_to_be_used = ARGV[1]
end

epw_file_path = File.expand_path(File.join(File.dirname(__FILE__), 'temporary.epw'))
if !ARGV[2].nil? && File.exist?(ARGV[2])
  epw_file_path = ARGV[2]
end


root_dir = File.join(File.dirname(__FILE__), '..')
out_path = File.expand_path("../spec/output/#{File.basename(xml_path, File.extname(xml_path))}/", File.dirname(__FILE__))

if File.exist?(out_path)
  FileUtils.rm_rf(out_path)
end
FileUtils.mkdir_p(out_path)

translator = BuildingSync::Translator.new(xml_path, out_path, epw_file_path, standard_to_be_used, false)
#translator.add_measure('Occupancy_Simulator')
translator.write_osm
translator.write_osws

osws = Dir.glob("#{out_path}/**/in.osw")

runner = OpenStudio::Extension::Runner.new(root_dir)
runner.run_osws(osws, 4)

puts 'bye'