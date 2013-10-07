require 'rake'
require 'rake/clean'
require 'crichton/external_document_store'

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
      store = Crichton::ExternalDocumentStore.new.download_link_and_store_in_document_store(args.link)
    end

    desc "Compare ALPS profile documents to documents in the external document store"
    task :check_external_documents do |t|
      puts Crichton::ExternalDocumentStore.new.compare_stored_documents_with_their_original_documents
    end
  end
end
