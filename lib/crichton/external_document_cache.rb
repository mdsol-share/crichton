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
      return read_datafile(link) if metadata && metadata_valid(metadata)
      get_link_and_update_cache(link, metadata)
    end

    private
    def metadata_valid(metadata)
      false
    end

    def metadata_etag(metadata)
      metadata[:headers] && metadata[:headers]['etag']
    end

    def metadata_time(metadata)
      metadata[:time]
    end

    def metadata_last_modified(metadata)
      metadata[:headers] && metadata[:headers]['last-modified']
    end

    def get_link_and_update_cache(link, metadata=nil)
      #response = Net::HTTP.get_response(URI(link_without_fragment(link)))
      uri = URI(link_without_fragment(link))
      request = Net::HTTP::Get.new(uri.request_uri)
      if metadata
        request['If-Modified-Since'] = metadata_last_modified(metadata).first if metadata_last_modified(metadata)
        request['If-None-Match'] = metadata_etag(metadata).first if metadata_etag(metadata)
      end
      response = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(request) }

      if response.code == '304'
        # Unchanged
        metadata[:time] = Time.now
        File.open(metafile_path(link), 'wb') {|f| f.write(metadata.to_yaml) }
        read_datafile(link)
      else
        # Fetched data
        File.open(datafile_path(link), 'wb') {|f| f.write(response.body) }
        new_metadata = {
          link: link_without_fragment(link),
          status: response.code,
          headers: response.to_hash,
          time: Time.now}
        File.open(metafile_path(link), 'wb') {|f| f.write(new_metadata.to_yaml) }
        response.body
      end
    end

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
  end
end
