require 'crichton/representor/serializer'
require "json"

module Crichton
  module Representor

    ##
    # Manages the serialization of a Crichton::Representor to an application/vnd.hale+json media-type.
    class HaleJsonSerializer < Serializer
      media_types hale_json: %w(application/vnd.hale+json)

    end
  end
end
