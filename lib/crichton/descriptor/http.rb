require 'crichton/descriptor/base'

module Crichton
  module Descriptor
    # Manages HTTP-protocol transition descriptors.
    class Http < Base 
      # @!macro array_reader
      descriptor_reader :content_types

      # @!macro array_reader
      descriptor_reader :headers

      # @!macro string_reader
      descriptor_reader :method

      # @!macro hash_reader
      descriptor_reader :slt

      # @!macro hash_reader
      descriptor_reader :status_codes

      # @!macro string_reader
      descriptor_reader :uri
    end
  end
end
