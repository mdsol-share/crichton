require 'rake'
require 'rake/clean'
require 'fileutils'
require 'nokogiri'

CLOBBER.include('columbo', 'coverage')
CLOBBER.uniq!

desc 'Runs shamus and adds coverage'
task :shamus do
  STDOUT.puts 'Generating validation documents'
  generate = `shamus`
  STDOUT.puts generate

  if File.exists?('coverage')
    STDOUT.puts 'Adding coverage report'
    FileUtils.copy_entry('coverage', 'columbo/coverage') 
    
    filename = File.join(File.expand_path("../..", __FILE__), 'columbo/index.html')
    doc = Nokogiri::HTML(open(filename))
    
    link_list = doc.css('ul').first
    link = Nokogiri::XML::Node.new "a", doc
    link.content = 'Coverage'
    link['href'] = 'coverage/index.html'

    li = Nokogiri::XML::Node.new "li", doc
    li.add_child(link)
    link_list.add_child(li)
    
    File.open(filename, 'w') { |f| f.puts doc.to_s }
  end
end
