module Crichton
  class HttpDescriptor < BaseDescriptor 
    ##
    # Constructs a new instance of HttpDescriptor.
    #
    # @param [Hash] resource_descriptor The parent resource descriptor instance.                                                              # 
    # @param [Hash] descriptor_document The section of the descriptor document representing this instance.
    # @param [Hash] options Optional arguments.
    # @option options [Symbol] :id Set or override the id of the descriptor.
    def initialize(resource_descriptor, descriptor_document, options = {})
      super(descriptor_document, options)
      @resource_descriptor = resource_descriptor
    end

    ##
    # The parent resource descriptor.
    #
    # @return [Hash] The resource descriptor.
    attr_reader :resource_descriptor

    ##
    # The content types supported by the transition.
    #
    # @return [Array] The media-types.
    def content_types
      descriptor_document['content_types']
    end

    ##
    # The headers that should be returned with a response.
    #
    # @return [Array] The headers.
    def headers
      descriptor_document['headers']
    end

    ##
    # The uniform-interface method.
    #
    # @return [String] The method.
    def method
      descriptor_document['method']
    end

    ##
    # The service level target specification for the transition.
    #
    # @return [Hash] The slt object.
    def slt
      descriptor_document['slt']
    end

    ##
    # The status codes associated with the transition.
    #
    # Used to generate transition specific human-readable documentation of the status codes that may be returned.
    #
    # @return [Hash] The status codes.
    def status_codes
      descriptor_document['status_codes']
    end

    ##
    # The uri of the transition.
    #
    # @return [String] The (templated) URI.
    def uri
      descriptor_document['uri']
    end
  end
end
