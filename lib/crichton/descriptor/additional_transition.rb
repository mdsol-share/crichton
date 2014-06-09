require 'crichton/descriptor/descriptor_keywords'

module Crichton
  module Descriptor
    class AdditionalTransition

      attr_reader :name, :url

      def initialize(name, url)
        @name = name
        @url = url.is_a?(Hash) ? url[HREF] : url
      end

      def safe?
        true
      end

      def templated?
        false
      end

      def to_a
        [name, url]
      end
    end
  end
end
