require 'crichton'

namespace :load do
  desc 'Load the most recent resource descriptor document from crichton fixtures directory.'
  task :resource_descriptor => :environment do
    task :force => :environment do; end
    option = ARGV.last
    gem = Bundler.load.specs.find{ |g| g.name == 'crichton' }
    sample_drd_doc = File.join(gem.full_gem_path, '/spec/fixtures/resource_descriptors/drds_descriptor_v1.yml')
    api_filename = File.join(Dir.pwd, Crichton.descriptor_directory, 'drds_sample_descriptor.yml')
    FileUtils.mkdir(Crichton.descriptor_directory) unless Dir.exists?(Crichton.descriptor_directory)
    if File.exist?(api_filename)
      unless FileUtils.identical?(sample_drd_doc, api_filename) || option == 'force'
        puts "Your sample descriptor file is different from Crichton's sample descriptor file. " <<
          "Please execute: 'bundle exec rake load:resource_descriptor force' to use Crichton's sample descriptor file. " <<
          "Backup copy of existing file will be created!"
      end
      if option == 'force'
        FileUtils.cp(api_filename, "#{api_filename}.backup")
        FileUtils.cp(sample_drd_doc, api_filename)
        puts "Sample resource descriptor file was updated at #{api_filename}"
      end
    else
      FileUtils.cp(sample_drd_doc, api_filename)
      puts "Sample resource descriptor file created at #{api_filename}"
    end
  end
end
