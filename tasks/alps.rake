require 'rake'
require 'rake/clean'
require 'crichton/external_document_store'
require 'diffy'

begin
  namespace :alps do
    desc "Generate ALPS profile documents"
    task :generate_profiles do
      directory = 'alps_profiles'
      Dir::mkdir(directory) unless Dir.exists?(directory)
      Crichton.raw_profile_registry.keys.each do |key|
        %w(xml json).each do |ext|
          doc = Crichton.raw_profile_registry[key].send("to_#{ext}")
          File.open(File.join(directory, "#{key}.#{ext}"), 'w') { |f| f.write(doc) }
        end
      end
    end

    desc "Download ALPS profile documents to the external document store"
    task :store_external_document, :link do |t, args|
      store = Crichton::ExternalDocumentStore.new
      new_data = store.download(args.link)
      old_data = store.get(args.link)
      write_data = true
      if old_data && old_data != new_data
        STDOUT.puts "The existing and downloaded data doesn't match. Are you sure you want to overwrite it? (y/n)"
        input = STDIN.gets.strip
        write_data = false unless input == 'y'
      end
      store.write_data_to_store(args.link, new_data) if write_data
    end

    desc "Compare ALPS profile documents to documents in the external document store"
    task :check_external_documents do |t|
      store = Crichton::ExternalDocumentStore.new
      link_list = store.get_list_of_stored_links
      link_list.each do |link|
        new_data = store.download(link)
        old_data = store.get(link)
        if old_data != new_data
          puts "Data of link #{link} has changed!"
          puts  Diffy::Diff.new(old_data, new_data, :context => 2)
        end
      end
    end
  end
end
