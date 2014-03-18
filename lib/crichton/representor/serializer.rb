require 'crichton/representor'

module Crichton
  module Representor
    class Serializer
      class << self
        ##
        # Serializer factory method that returns a serializer associated with a particular media-type.
        #
        # @param [String, Symbol] type The media-type associated with the serializer.
        # @param [Cricthon::Representor] representor That resource representor instance.
        # @param [Hash] options Serialization options.
        #
        # @return [Cricthon::Representor::Serializer] The built serializer.
        def build(type, representor, options = nil)
          options ||= {}
          
          if serializer_class = registered_serializers[type.to_sym]
            serializer_class.new(representor, options)
          else
            raise(Crichton::RepresentorError,
              "No representor serializer is registered that corresponds to the type '#{type}'.")
          end
        end

        ##
        # Define content types arrays corresponding to media types registered with serializer.
        #
        # @example
        #  class MediaTypeSerializer < Crichton::Representor::Serializer
        #    media_types  media_type: %w(application/media_type), other_media_type: %w(application/other_media_type)
        #  end
        #
        #  Crichton::Representor::Serializer.registered_media_types[:media_type] #=> %w(application/media_type)
        #  Crichton::Representor::Serializer.registered_media_types[:other_media_type]  #=> %w(application/other_media_type)
        #
        # @param [Hash] types Hash of content types arrays keyed by media types.
        def media_types(types)
          unless types[default_media_type]
            raise(ArgumentError,
              "The first media type in the list of available media_types should be #{self.default_media_type}")
          end

          types.each do |media_type, content_types|
            register_serializer(media_type, self)
            register_media_types(media_type, content_types)
          end
        end

        ##
        # Returns the media-type of the Serializer.
        #
        # @return [Symbol]
        def default_media_type
          @default_media_type ||= begin
            name = self.name
            unless name =~ /\w+Serializer$/
              raise(Crichton::RepresentorError,
                "Subclasses of Chrichton::Serializer must follow the naming convention " <<
                "OptionalModule::MediaTypeSerializer. #{self.name} is an invalid subclass name.")
            end
  
            name.demodulize.gsub(/Serializer$/, '').underscore.to_sym
          end
        end

        ##
        # The registered serializers by media type.
        #
        # @return [Hash] The mapped serializers keyed by media-type.
        def registered_serializers
          @registered_serializers ||= {}
        end

        ##
        # The registered media types with content types.
        #
        # @return [Hash] The mapped content_types keyed by media-type.
        def registered_media_types
          @registered_media_types ||= {}
        end

        private
          def register_serializer(media_type, serializer)
            Serializer.registered_serializers[media_type] = serializer
          end

          def register_media_types(media_type, content_types)
            Serializer.registered_media_types[media_type] = content_types

            if defined?(Rails)
              register_mime_types(media_type, content_types)
              ActionController::Renderers.add media_type do |obj, options|
                type = media_type
                if obj.is_a?(Crichton::Representor)
                  obj.to_media_type(type, options) do |serializer|
                    serializer.response_headers.each do |k,v|
                      response.headers[k] = v
                    end
                  end
                else
                  raise(ArgumentError,
                    "The object #{obj.inspect} is not a Crichton::Representor. " <<
                    "Please include module Crichton::Representor or Crichton::Representor::State in your object" <<
                    "or use Crichton::Representor::Factory to decorate your object as a representor.")
                end
              end
            end
          end

        def register_mime_types(media_type, content_types)
          if Mime::Type.lookup_by_extension(media_type)
            puts "Un-registering already defined mime type #{media_type.to_s.upcase}"
            Mime::Type.unregister(Mime::Type.lookup_by_extension(media_type).to_sym)
          end
          puts "Registering mime type #{media_type.to_s.upcase} with following content_types #{content_types}"
          Mime::Type.register(content_types.shift, media_type, content_types)
        end
      end

      ##
      #  @param [Crichton::Representor] object The representor object.
      # @param [Hash] options Serialization options.
      def initialize(object, options = nil)
        unless object.is_a?(Crichton::Representor)
          raise ArgumentError, "The object #{object.inspect} is not a Crichton::Representor."
        end
        
        @object, @options = object, options || {}
      end

      def used_datalists
        @used_datalists ||= []
      end

      def response_headers
        @response_headers ||= {}
      end

      ##
      # Returns a serialized media-type for the response as a Hash or XML. This method is used for serialization
      # of a response and should not typically be used as the method to generate the final response, which should be
      # returned using the <tt>to_media_type</tt> method instead.
      #
      # This abstract method must be overridden in concrete serializer subclasses.
      def as_media_type(options = {})
        raise("The method #as_media_type is an abstract method of the Crichton::Serializer class and must be " <<
          "overridden in the #{self.class.name} subclass.")
      end

      ##
      # Returns the serializer as the final media-type in correct format.
      #
      # Sub-classes should override the default functionality which delegates to #as_media_type, if, for example, 
      # the result should be returned as JSON string.
      #
      # @example
      #   # application/hal+json
      #   def to_media_type(options = {})
      #     self.as_media_type(options).to_json
      #   end
      #
      # @param [Hash] options Conditional options.
      def to_media_type(options = {})
        self.as_media_type(options)
      end
    end
  end
end
