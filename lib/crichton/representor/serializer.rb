require 'crichton/representor'

module Crichton
  module Representor
    class Serializer
      class << self  
        ##
        # Serializer factory method that returns a serializer associated with a particular media-type.
        #
        # @param [String, Symbol] type The media-type associated with the serializer.
        # @param [Cricthon::Representor] object That resource representor instance.
        # @param [Hash] options Serializtaion options.
        #
        # @return [Cricthon::Representor::Serializer] The built serializer.
        def build(type, representor, options = nil)
          options ||= {}
          
          if serializer_class = registered_serializers[type.to_sym]
            serializer_class.new(representor, options)
          else
            raise Error, "No representor serializer is registered that corresponds to the type '#{type}'."
          end
        end
        
        ##
        # The registered serializers by media type.
        #
        # @return [Hash] The mapped serializers keyed by media-type.
        def registered_serializers
          @registered_serializers ||= {}
        end

        # @private
        # Subclasses self-register themselves
        def inherited(subclass)
          registered_serializers[find_type(subclass)] = subclass
        end
      
      private
        def find_type(subclass)
          name = subclass.name
          unless name =~ /Serializer$/
            raise Error, "Subclasses of #{self.name} must follow the naming convention " <<
              "OptionalModule::MediaTypeSerializer. #{subclass.name} is an invalid subclass name."
          end
  
          name.demodulize.gsub(/Serializer$/, '').underscore.to_sym
        end
      end
  
      ##
      # @param [Crichton::Representor] object The representor object.
      # @param [Hash] options Serialization options.
      def initialize(object, options = nil)
        unless object.is_a?(Crichton::Representor)
          raise ArgumentError, "The object #{object.inspect} is not a Crichton::Representor."
        end
        
        @object, @options = object, options || {}
      end
    end
  end
end
