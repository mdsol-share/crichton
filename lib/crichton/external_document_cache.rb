require 'json'
require 'addressable/uri'
require 'net/http'
require 'fileutils'
require 'crichton/helpers'
require 'crichton/configuration'

module Crichton

  module CacheMetaDataHelper
    def metadata_etag(metadata)
      metadata['headers'] && metadata['headers']['etag']
    end

    def metadata_last_modified(metadata)
      metadata['headers'] && metadata['headers']['last-modified']
    end

    def write_metadata_with_updated_time(link, metadata)
      if metadata
        metadata[:time] = Time.now
        File.open(metafile_path(link), 'wb') { |f| f.write(metadata.to_json) }
      end
    end

    def read_meta(link)
      metapath = metafile_path(link)
      File.exists?(metapath) ? File.open(metapath, 'rb') { |f| JSON.parse(f.read) } : nil
    end

    def metadata_valid?(metadata, timeout = 600)
      # The default timeout is to be used when no explicit timeout is set by the service
      timeout = determine_timeout(parsed_cache_control_header(metadata)) if cache_control_header_present?(metadata)
      Time.parse(metadata['time']) + timeout > Time.now
    end

    def cache_control_header_present?(metadata)
      metadata['headers'] && metadata['headers']['cache-control']
    end

    def parsed_cache_control_header(metadata)
      metadata['headers']['cache-control'].first.split(',').map { |y| y.strip.split('=') }
    end

    def determine_timeout(cache_control_elements)
      max_age = cache_control_elements.assoc('max-age')
      timeout = max_age[1].to_i if max_age
      # re-validate in case no cache or must-revalidate
      timeout = 0 if cache_control_elements.assoc('must-revalidate')
      timeout = 0 if cache_control_elements.assoc('no-cache')
      timeout
    end

  end

  class ExternalDocumentCache
    include Crichton::Helpers::ConfigHelper
    include Crichton::CacheMetaDataHelper

    def initialize(cache_path = nil)
      @cache_path = cache_path || config.external_documents_cache_directory
      FileUtils.mkdir_p(@cache_path) unless Dir.exists?(@cache_path)
    end

    def get(link)
      metadata = read_meta(link)
      return read_datafile(link) if metadata && metadata_valid?(metadata)
      get_link_and_update_cache(link, metadata)
    end

    private
    def get_link_and_update_cache(link, metadata = nil)
      uri = URI(link_without_fragment(link))
      request = assemble_request(metadata, uri)
      begin
        response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
        if ['304', '404'].include?(response.code)
          write_metadata_with_updated_time(link, metadata) if response.code == '304'
          read_datafile(link)
        else
          log_changed_cache_data(link, response)
          write_data_to_cache_files(link, response)
          response.body
        end
      rescue Errno::ECONNREFUSED => e
        logger.warn("Log connection refused: #{uri}")
        # In case of failure, use the (old) cache anyway
        return read_datafile(link)
      rescue => e
        logger.warn("#{e.message} while getting #{uri}")
        # In case of failure, use the (old) cache anyway
        return read_datafile(link)
      end
    end

    def log_changed_cache_data(link, response)
      data_file_path = datafile_path(link)
      if File.exists?(data_file_path)
        old_data = File.open(data_file_path, 'rb') { |f| f.read }
        logger.warn("Data was modified for #{link}!") if old_data != response.body
      else
        logger.info("Data appeared for #{link}") if response.body
      end
    end

    def write_data_to_cache_files(link, response)
      File.open(datafile_path(link), 'wb') { |f| f.write(response.body) }
      # Write the metadata
      new_metadata = {
          link:    link_without_fragment(link),
          status:  response.code,
          headers: response.to_hash,
          time:    Time.now }
      File.open(metafile_path(link), 'wb') { |f| f.write(new_metadata.to_json) }
    end

    def assemble_request(metadata, uri)
      request = Net::HTTP::Get.new(uri.request_uri)
      # Conditional GET support - if we have the headers in the metadata then add the conditional GET request headers
      if metadata
        request['If-Modified-Since'] = metadata_last_modified(metadata).first if metadata_last_modified(metadata)
        request['If-None-Match'] = metadata_etag(metadata).first if metadata_etag(metadata)
      end
      request
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

    def read_datafile(link)
      path = datafile_path(link)
      File.open(path, 'rb') { |f| f.read } if File.exists?(path)
    end
  end
end
