# Run a BuildingSync XML file to generate synthetic smart meter data

require 'openstudio/extension'
require 'openstudio/model_articulation/os_lib_model_generation_bricr'
require 'buildingsync'
require 'buildingsync/translator'
require 'openstudio/occupant_variability'

if ARGV[0].nil? || !File.exist?(ARGV[0])
  puts 'usage: bundle exec ruby simulate_bdgp_xml.rb path/to/xml/file'
  puts ".xml files only"
  exit(1)
end

xml_path = ARGV[0]
root_dir = File.join(File.dirname(__FILE__), '..')
out_path = File.expand_path("../output/#{File.basename(xml_path, File.extname(xml_path))}/", File.dirname(__FILE__))

if File.exist?(out_path)
  FileUtils.rm_rf(out_path)
end
FileUtils.mkdir_p(out_path)

epw_file_path = File.expand_path(File.join(File.dirname(__FILE__), 'temporary.epw'))

standard_to_be_used = 'CaliforniaTitle24'

translator = BuildingSync::Translator.new(xml_path, out_path, epw_file_path, standard_to_be_used)
translator.write_osm
translator.write_osws

osws = Dir.glob("#{out_path}/**/in.osw")

runner = OpenStudio::Extension::Runner.new(root_dir)
runner.run_osws(osws, 4)

puts 'bye'