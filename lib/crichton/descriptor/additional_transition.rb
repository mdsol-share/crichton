require 'crichton/descriptor/descriptor_keywords'

module Crichton
  module Descriptor

    #TODO Investigate if we should constrain this to parameters defined in the profile or
    # IANA registered links in the future.
    class AdditionalTransition
      TEMPLATED = 'templated'

      attr_reader :name, :link

      ##
      # Constructs a new instance of AdditionalTransition.
      #
      # @param name [String] The name of the transition.
      # @param link [Hash or String] The link hash with 'href' key or the URL of the transition.
      def initialize(name, link)
        @name = name.to_s
        @link = link
      end

      def url
        @url ||= link.is_a?(Hash) ? link[HREF] : link
      end

      def safe?
        true
      end

      def templated?
        @templated ||= (link.is_a?(Hash) ? link[TEMPLATED] : false) === true
      end

      def to_a
        [name, url]
      end
    end
  end
end
