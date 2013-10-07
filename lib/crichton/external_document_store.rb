require 'fileutils'
require 'crichton/helpers'
require 'diffy'

module Crichton
  class ExternalDocumentStore
    include Crichton::Helpers::ConfigHelper

    def self.compare_stored_documents_with_their_original_documents
      store = Crichton::ExternalDocumentStore.new
      store.get_list_of_stored_links.each do |link|
        new_data = store.download(link)
        old_data = store.get(link)
        if old_data != new_data
          puts "Data of link #{link} has changed!"
          puts  Diffy::Diff.new(old_data, new_data, :context => 2)
        end
      end
    end

    def self.download_link_and_store_in_document_store(link)
      store = Crichton::ExternalDocumentStore.new
      new_data = store.download(link)
      old_data = store.get(link)
      write_data = true
      if old_data && old_data != new_data
        STDOUT.puts "The existing and downloaded data doesn't match. Are you sure you want to overwrite it? (y/n)"
        input = STDIN.gets.strip
        write_data = false unless input == 'y'
      end
      store.write_data_to_store(link, new_data) if write_data
    end

    def initialize(document_store_path = nil)
      @document_store_path = document_store_path || config.external_documents_store_directory
      FileUtils.mkdir_p(@document_store_path) unless Dir.exists?(@document_store_path)
    end

    def get(link)
      read_datafile(link)
    end

    # These three methods are intended for managing the store - in particular by rake tasks.
    def download(link)
      uri = URI(link_without_fragment(link))
      request = Net::HTTP::Get.new(uri.request_uri)
      response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
      response.body
    end

    def write_data_to_store(link, data)
      File.open(metafile_path(link), 'wb') { |f| f.write(link) }
      File.open(datafile_path(link), 'wb') { |f| f.write(data) }
    end

    def get_list_of_stored_links
      Dir.glob(File.join([@document_store_path, '*.meta'])).map { |n| File.open(n, 'rb') {|f| f.read}}
    end

    private
    def datafile_path(link)
      url = URI.parse(link)
      host_port_and_path = "#{url.host}:#{url.port.to_s}#{url.path}"
      snaked_host_port_and_path = host_port_and_path.gsub(/\W/, '_')
      File.join(@document_store_path, "#{snaked_host_port_and_path}.profile")
    end

    def metafile_path(link)
      url = URI.parse(link)
      host_port_and_path = "#{url.host}:#{url.port.to_s}#{url.path}"
      snaked_host_port_and_path = host_port_and_path.gsub(/\W/, '_')
      File.join(@document_store_path, "#{snaked_host_port_and_path}.meta")
    end

    def read_datafile(link)
      path = datafile_path(link)
      File.open(path, 'rb') { |f| f.read } if File.exists?(path)
    end

    def link_without_fragment(link)
      parsed_link = Addressable::URI.parse(link)
      parsed_link.fragment = nil
      parsed_link.to_s
    end
  end
end
