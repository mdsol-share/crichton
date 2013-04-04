module Crichton
  ##
  # References descriptor link elements.
  class LinkDescriptor
    
    ##
    #
    # @param [String] rel The link relationship.
    # @param [String] href The link URI.
    def initialize(rel, href)
      @rel = rel
      @href = href
    end

    ##
    # The URL of the link.
    #
    # @return [String] The URL.
    attr_reader :href
    
    ##
    # The link semantic relationship.
    #
    # @return [String] The relationship.
    attr_reader :rel
  end
end
