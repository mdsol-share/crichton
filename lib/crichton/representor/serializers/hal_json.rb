require 'crichton/representor/serializer'
require "json"

module Crichton
  module Representor
    ##
    # Manages the serialization of a Crichton::Representor to an application/hal+json media-type.
    class HalJsonSerializer < Serializer
      media_types hal_json: %w(application/hal+json)
    end
  end
end
