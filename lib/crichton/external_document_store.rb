require 'fileutils'

module Crichton
  class ExternalDocumentStore
    def initialize(document_store_path = nil)
      @document_store_path = document_store_path || Crichton.config.external_documents_store_directory
      FileUtils.mkdir_p(@document_store_path) unless Dir.exists?(@document_store_path)
    end

    def get(link)
      read_datafile(link)
    end

    private
    def datafile_path(link)
      url = URI.parse(link)
      host_port_and_path = "#{url.host}:#{url.port.to_s}#{url.path}"
      snaked_host_port_and_path = host_port_and_path.gsub(/\W/, '_')
      File.join(@document_store_path, "#{snaked_host_port_and_path}.profile")
    end

    def read_datafile(link)
      path = datafile_path(link)
      File.exists?(path) ? File.open(path, 'rb') {|f| f.read } : nil
    end
  end
end
