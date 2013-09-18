require 'addressable/uri'

module Crichton
  class ExternalDocumentCache
    def initialize(cache_path = nil)
      @cache_path = cache_path || Crichton.config.external_documents_cache_directory
      Dir::mkdir(@cache_path) unless Dir.exists?(@cache_path)
    end

    def get(link)
      parsed_link = Addressable::URI.parse(link)
      parsed_link.fragment = nil
      link_without_fragment = parsed_link.to_s
      filename = Digest::MD5.hexdigest(link_without_fragment)
      path = File.join(@cache_path, "#{filename}.cache")
      metapath = File.join(@cache_path, "#{filename}.meta")
      if File.exists?(path)
        File.open(path, 'rb') {|f| f.read }
      else
        data = Net::HTTP.get(URI(link_without_fragment))
        File.open(path, 'wb') {|f| f.write(data) }
        File.open(metapath, 'wb') {|f| f.write(link_without_fragment) }
        data
      end
    end
  end
end
