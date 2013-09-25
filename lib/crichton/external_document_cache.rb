require 'json'
require 'addressable/uri'
require 'net/http'
require 'fileutils'
require 'crichton/config_helper'

module Crichton
  class ExternalDocumentCache
    include Crichton::Helpers::ConfigHelper

    def initialize(cache_path = nil)
      @cache_path = cache_path || config.external_documents_cache_directory
      FileUtils.mkdir_p(@cache_path) unless Dir.exists?(@cache_path)
    end

    def get(link)
      metadata = read_meta(link)
      read_datafile(link) if metadata && metadata_valid(metadata)
      get_link_and_update_cache(link, metadata)
    end

    private
    def metadata_valid(metadata, timeout = 600)
      # The default timeout is to be used when no explicit timeout is set by the service
      if metadata['headers'] && metadata['headers']['cache-control']
        cache_control_elements = metadata['headers']['cache-control'].first.split(", ").map { |y| y.split('=') }
        max_age = cache_control_elements.assoc('max-age')
        timeout = max_age[1].to_i if max_age
        # re-validate in case no cache or must-revalidate
        timeout = 0 if cache_control_elements.assoc('must-revalidate')
        timeout = 0 if cache_control_elements.assoc('no-cache')
      end
      Time.parse(metadata['time']) + timeout > Time.now
    end

    def metadata_etag(metadata)
      metadata['headers'] && metadata['headers']['etag']
    end

    def metadata_last_modified(metadata)
      metadata['headers'] && metadata['headers']['last-modified']
    end

    def get_link_and_update_cache(link, metadata=nil)
      uri = URI(link_without_fragment(link))
      request = Net::HTTP::Get.new(uri.request_uri)
      # Conditional GET support - if we have the headers in the metadata then add the conditional GET request headers
      if metadata
        request['If-Modified-Since'] = metadata_last_modified(metadata).first if metadata_last_modified(metadata)
        request['If-None-Match'] = metadata_etag(metadata).first if metadata_etag(metadata)
      end
      begin
        response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
      rescue Errno::ECONNREFUSED => e
        #TODO: Use logger
        puts "Log connection refused: #{uri.request_uri}"
        # In case of failure, use the (old) cache anyway
        return read_datafile(link)
      rescue => e
        puts "Error: #{e.message} while getting #{uri.request_uri}"
        # In case of failure, use the (old) cache anyway
        return read_datafile(link)
      end

      if response.code == '304'
        # Unchanged - just update time in metadata
        metadata[:time] = Time.now
        File.open(metafile_path(link), 'wb') { |f| f.write(metadata.to_json) }
        read_datafile(link)
      elsif response.code == '404'
        # not there
        read_datafile(link)
      else
        data_file_path = datafile_path(link)
        # This block is for some debugging instrumentation: If the data changed, log it.
        # That may indicate that some changes happened that need to be looked into.
        if File.exists?(data_file_path)
          old_data = File.open(data_file_path, 'rb') { |f| f.read }
          if old_data != response.body
            #TODO: Use logger
            puts "Data was modified for #{link}!"
          end
        else
          if response.body
            #TODO: Use logger
            puts "Data appeared for #{link}"
          end
        end
        # Write the content
        File.open(data_file_path, 'wb') { |f| f.write(response.body) }
        # Write the metadata
        new_metadata = {
          link: link_without_fragment(link),
          status: response.code,
          headers: response.to_hash,
          time: Time.now}
        File.open(metafile_path(link), 'wb') { |f| f.write(new_metadata.to_json) }
        return response.body
      end
    end

    def filename_base_for_link(link)
      # The file names in the cache are just hashes of the URL. Should be safe enough. Or are we worried about
      # malicious collisions here?
      Digest::MD5.hexdigest(link_without_fragment(link))
    end

    def datafile_path(link)
      File.join(@cache_path, "#{filename_base_for_link(link)}.cache")
    end

    def metafile_path(link)
      File.join(@cache_path, "#{filename_base_for_link(link)}.meta.json")
    end

    def link_without_fragment(link)
      parsed_link = Addressable::URI.parse(link)
      parsed_link.fragment = nil
      parsed_link.to_s
    end

    def read_meta(link)
      metapath = metafile_path(link)
      File.exists?(metapath) ? File.open(metapath, 'rb') { |f| JSON.parse(f.read) } : nil
    end

    def read_datafile(link)
      path = datafile_path(link)
      File.exists?(path) ? File.open(path, 'rb') { |f| f.read } : nil
    end
  end
end
