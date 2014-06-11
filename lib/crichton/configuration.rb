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

    def include_discovery_middleware?
      @include_discovery_middleware ||= (@config['include_discovery_middleware'] === true)
    end

    def resource_home_response_expiry
      @resource_home_response_expiry ||= { 'expiry' => (@config['resource_home_response_expiry'] || 20) }
    end

    def include_alps_middleware?
      @include_alps_middleware ||= (@config['include_alps_middleware'] === true)
    end

    def alps_profile_response_expiry
      @alps_profile_response_expiry ||= { 'expiry' => (@config['alps_profile_response_expiry'] || 20) }
    end

    ##
    # @!attribute [r] css_uri
    # The URI where CSS is hosted.
    #
    # @return [Array] The CSS URI.
    def css_uri
      @css_uri ||= (css = *@config['css_uri'])
    end

    ##
    # @!attribute [r] js_uri
    # The URI where JS is hosted.
    #
    # @return [Array] The JS URI.
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
    end
  end
end
