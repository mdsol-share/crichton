require 'yaml'
require 'addressable/uri'

module Crichton
  class ExternalDocumentCache
    def initialize(cache_path = nil)
      @cache_path = cache_path || Crichton.config.external_documents_cache_directory
      Dir::mkdir(@cache_path) unless Dir.exists?(@cache_path)
    end

    def get(link)
      metadata = read_meta(link)
      if metadata
        read_datafile(link)
      else
        response = Net::HTTP.get_response(URI(link_without_fragment(link)))
        write_response(link, response)
      end
    end

    private
    def filename_base_for_link(link)
      Digest::MD5.hexdigest(link_without_fragment(link))
    end

    def datafile_path(link)
      File.join(@cache_path, "#{filename_base_for_link(link)}.cache")
    end

    def metafile_path(link)
      File.join(@cache_path, "#{filename_base_for_link(link)}.meta.yaml")
    end

    def link_without_fragment(link)
      parsed_link = Addressable::URI.parse(link)
      parsed_link.fragment = nil
      parsed_link.to_s
    end

    def read_meta(link)
      metapath = metafile_path(link)
      if File.exists?(metapath)
        YAML.parse_file(metapath).to_ruby
      else
        nil
      end
    end

    def read_datafile(link)
      path = datafile_path(link)
      if File.exists?(path)
        File.open(path, 'rb') {|f| f.read }
      else
        nil
      end
    end

    def write_response(link, response)
      File.open(datafile_path(link), 'wb') {|f| f.write(response.body) }
      metadata = {
        link: link_without_fragment(link),
        status: response.code,
        headers: response.to_hash,
        time: Time.now}
      File.open(metafile_path(link), 'wb') {|f| f.write(metadata.to_yaml) }
      response.body
    end
  end
end
