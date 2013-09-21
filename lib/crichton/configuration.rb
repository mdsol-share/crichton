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
    %w(alps deployment discovery documentation).each do |attribute|
      method = "#{attribute}_base_uri"
      define_method(method) { @config[method] }
    end

    ##
    # @!attribute [r] css_uri
    # The URI where CSS is hosted.
    #
    # @return [String] The URI.
    define_method('css_uri') { @config['css_uri'] }

    ##
    # @param [Hash] config The configuration hash.
    # @option config [String] alps_base_uri
    # @option config [String] deployment_base_uri
    # @option config [String] discovery_base_uri
    # @option config [String] documentation_base_uri
    # @option config [String] css_uri
    #
    # @return [Configuration] The configuration instance.
    def initialize(config)
      @config = config || {}
    end
  end
end
