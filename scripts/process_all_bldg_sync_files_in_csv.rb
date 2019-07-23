# Run a BuildingSync XML file to generate synthetic smart meter data

require 'openstudio/extension'
require 'openstudio/model_articulation/os_lib_model_generation_bricr'
require 'buildingsync'
require 'buildingsync/translator'
require 'openstudio/occupant_variability'

if ARGV[0].nil?
  puts 'usage: bundle exec ruby process_all_bldg_sync_files_in_csv.rb path/to/csv/file'
  puts "must provide a .csv file"
  exit(1)
end

def simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path)
  out_path = File.expand_path("../output/#{File.basename(xml_file_path, File.extname(xml_file_path))}/", File.dirname(__FILE__))
  root_dir = File.join(File.dirname(__FILE__), '..')

  translator = BuildingSync::Translator.new(xml_file_path, out_path, epw_file_path, standard)
  translator.write_osm
  translator.write_osws

  osws = Dir.glob("#{out_path}/**/in.osw")

  runner = OpenStudio::Extension::Runner.new(root_dir)
  return runner.run_osws(osws, 4)
end

csv_file_path = ARGV[0]


out_path = File.expand_path("../output/#{File.basename(csv_file_path, File.extname(csv_file_path))}/", File.dirname(__FILE__))

if File.exist?(out_path)
  FileUtils.rm_rf(out_path)
end
FileUtils.mkdir_p(out_path)

log_file_path = csv_file_path + '.log'

csv_table = CSV.read(csv_file_path)
log = File.open(log_file_path, 'w')
csv_table.each do |xml_file, standard, epw_file|
  log.puts("processing xml_file: #{xml_file} - standard: #{standard} - epw_file: #{epw_file}")

  xml_file_path = File.expand_path("../bdgp_output/#{xml_file}/", File.dirname(__FILE__))
  out_path = File.expand_path("../output/#{File.basename(xml_file, File.extname(xml_file))}/", File.dirname(__FILE__))
  epw_file_path = File.expand_path("../scripts/#{epw_file}/", File.dirname(__FILE__))
  result = simulate_bdgp_xml_path(xml_file_path, standard, epw_file_path)

  puts "...completed: #{result} and osm file exist: #{File.exist?("#{out_path}/in.osm")}"
  log.puts("...completed: #{result} and osm file exist: #{File.exist?("#{out_path}/in.osm")}")

  output_dirs = []
  Dir.glob("#{out_path}/**/") { |output_dir| output_dirs << output_dir }
  output_dirs.each do |output_dir|
    if !output_dir.include? "/SR"
      if output_dir != out_path
        sql_file = File.expand_path(output_dir, "/eplusout.sql")
        if !File.exist?(sql_file)
          log.puts("...ERROR: #{sql_file} does not exist, simulation was unsucessful}")
          log.flush
        end
      end
    end
  end
end
log.close

puts 'bye'