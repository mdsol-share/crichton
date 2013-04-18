module Crichton
  # Manages the configuration of the Crichton environment.
  class Configuration

    ATTRIBUTES = %w(alps deployment discovery documentation)

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
    ATTRIBUTES.each do |attribute|
      method = "#{attribute}_base_uri"
      define_method(method) { @config[method] }
    end
    
    ##
    # @param [Hash] config The configuration hash.
    # @option config [string] alps_base_uri
    # @option config [string] deployment_base_uri
    # @option config [string] alps_base_uri
    # @option config [string] alps_base_uri
    #
    # @return [Configuration] The configuration instance.
    def initialize(config)
      @config = config || {}
    end
  end
end
