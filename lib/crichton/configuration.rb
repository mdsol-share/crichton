module Crichton
  # Manages the configuration of the Crichton environment.
  class Configuration

    ##
    # @!attribute [r] alps_base_uri
    # The base URI of the ALPS repository.
    #
    # @return [String] The URI.

    ##
    # @!attribute [r] deployment_base_uri
    # The base URI of the service.
    #
    # @return [String] The URI.

    ##
    # @!attribute [r] discovery_base_uri
    # The base URI of the discovery service.
    #
    # @return [String] The URI.

    ##
    # @!attribute [r] documentation_base_uri
    # The base URI where documentation is hosted.
    #
    # @return [String] The URI.
    %w(alps deployment discovery documentation crichton_proxy).each do |attribute|
      method = "#{attribute}_base_uri"
      define_method(method) { @config[method] }
    end

    def external_documents_cache_directory
      @config['external_documents_cache_directory'] || 'tmp/external_documents_cache'
    end

    def external_documents_store_directory
      @config['external_documents_store_directory'] || 'api_descriptors/external_documents_store'
    end

    def use_discovery_middleware?
      @use_discovery_middleware
    end

    def resources_catalog_response_expiry
      @resources_catalog_response_expiry ||= { 'expiry' => (@config['resources_catalog_response_expiry'] || 20) }
    end

    def use_alps_middleware?
      @use_alps_middleware
    end

    def alps_profile_response_expiry
      @alps_profile_response_expiry ||= { 'expiry' => (@config['alps_profile_response_expiry'] || 20) }
    end

    def service_level_target_header
      @service_level_target_header ||= @config['service_level_target_header'] || 'REQUEST_SLT'
    end

    ##
    # @!attribute [r] css_uri
    # The URI where CSS is hosted.
    #
    # @return [Array] The CSS URI.
    # TODO: Remove this when xhtml serializer refactored to Representors
    def css_uri
      @css_uri ||= (css = *@config['css_uri'])
    end

    ##
    # @!attribute [r] js_uri
    # The URI where JS is hosted.
    #
    # @return [Array] The JS URI.
    # TODO: Remove this when xhtml serializer refactored to Representors
    def js_uri
      @js_uri ||= (js = *@config['js_uri'])
    end

    ##
    # @param [Hash] config The configuration hash.
    # @option config [String] alps_base_uri
    # @option config [String] deployment_base_uri
    # @option config [String] discovery_base_uri
    # @option config [String] documentation_base_uri
    # @option config [Array] css_uri
    # @option config [Array] js_uri
    #
    # @return [Configuration] The configuration instance.
    def initialize(config)
      @config = config || {}
      @use_discovery_middleware = @config['use_discovery_middleware'] || false
      @use_alps_middleware = @config['use_alps_middleware'] || false
    end
  end
end
