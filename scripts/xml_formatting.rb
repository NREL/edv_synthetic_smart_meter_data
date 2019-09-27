require "rexml/document"

# make raw xml format to prettier format
def xml_formatting()

  #path to xml files
  dir_xml = 'C:/Users/JKIM4/Box Sync/Project Files/4 EDV/Example XMLs' #TODO: change path to be more generic later on
  
  if(File.exist?(dir_xml))
    Dir.glob(File.join(dir_xml, "*.xml")).each do |file|
	  #puts file
	  string = File.read(file) 
	  
	  doc = REXML::Document.new(string)
      formatter = REXML::Formatters::Pretty.new
	  
      # Compact uses as little whitespace as possible
      formatter.compact = true
      formatter.write(doc, $stdout)

      File.open("test.xml","w"){ |f| f.puts doc }
	  
    end
  end
end

xml_formatting()