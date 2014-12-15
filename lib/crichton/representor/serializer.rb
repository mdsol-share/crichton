require 'crichton/representor'
require 'crichton/helpers'

module Crichton
  module Representor
    class Serializer
      include Crichton::Helpers::ConfigHelper

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

        ##
        # Returns true if serializer has been registered
        def serializer?(serializer)
          Serializer.registered_serializers.key?(serializer)
        end

        private
          def register_serializer(media_type, serializer)
            Serializer.registered_serializers[media_type] = serializer
          end

          def register_media_types(media_type, content_types)
            Serializer.registered_media_types[media_type] = content_types

            if defined?(Rails)
              register_mime_types(media_type, content_types)
              #TODO: Move this block into its own method(s)
              ActionController::Renderers.add media_type do |obj, options|
                type = media_type
                if obj.is_a?(Crichton::Representor)
                  options.merge!({ top_level: true, override_links: { 'self' => request.url } }) if request.get?
                  options.merge!(semantics: :styled_microdata) if media_type == :html
                  if obj.respond_to?("to_#{type}")
                    if [:html, :xhtml].include?(media_type)
                      XHTMLSerializer.new(obj).as_media_type(options)
                    # TODO: Handle response headers!
                    else
                      # before: serializer.response_headers(obj, request).each { |k, v| response.headers[k] = v }
                      Representors::Representor.new(obj.to_representor(options)).to_media_type(type, options)
                    end
                  else
                    super
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
            Crichton::logger.info "Un-registering already defined mime type #{media_type.to_s.upcase}"
            Mime::Type.unregister(Mime::Type.lookup_by_extension(media_type).to_sym)
          end
          Crichton::logger.info "Registering mime type #{media_type.to_s.upcase} with following content_types #{content_types}"
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

      def response_headers(object, request)
        @response_headers ||= {}.tap do |response_headers|
          resource = Crichton.raw_profile_registry[object.class.resource_descriptor_id]
          protocol_transition = resource.protocol_route(request.scheme, request[:controller], request[:action])
          if protocol_transition && (slt = protocol_transition.slt)
            response_headers[config.service_level_target_header] = slt.map { |k, v| "#{k}=#{v}" }.join(',')
          end
          response_headers.merge!(object.response_headers(@options))
        end
      end
    end
  end
end
