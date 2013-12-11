require 'crichton/representor/serializer'
require 'crichton/representor/serializers/json_home'
require "json"

module Crichton
  module Discovery

    class EntryPoints
      include Crichton::Representor
      represents :entry_points

      attr_reader :resources

      ##
      #
      # Saves a collection of EntryPoint objects eventually used in serialization
      #
      # @params [Set] resources A Set collection of EntryPoint objects
      def initialize(resources)
        @resources = resources
      end
    end
  end
end
