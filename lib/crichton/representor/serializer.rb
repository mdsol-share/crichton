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
        # Define alternate media types that should return the same serializer.
        # 
        # @example
        #  class XHTMLSerializer < Crichton::Representor::Serializer
        #    alternate_media_types :html
        #  end
        #
        #  Crichton::Representor::Serializer.registered_serializers[:xhtml] #=> XHTMLSerializer
        #  Crichton::Representor::Serializer.registered_serializers[:html]  #=> XHTMLSerializer
        #
        def alternate_media_types(*args)
          @alternate_media_types ||= [] 
          @alternate_media_types |= args.map(&:to_sym)
          
          @alternate_media_types.each { |media_type| register_serializer(media_type, self) }
        end

        ##
        # Define content types arrays corresponding to media types registered with serializer.
        #
        # @example
        #  class MediaTypeSerializer < Crichton::Representor::Serializer
        #    alternate_media_types :hal_json
        #    content_types  %w(application/halo+json application/json), %w(application/hal+json)
        #  end
        #
        #  Crichton::Representor::Serializer.registered_media_types[:mediatype] #=> %w(application/halo+json application/json)
        #  Crichton::Representor::Serializer.registered_media_types[:hal_json]  #=> %w(application/hal+json)
        #
        def content_types(*types)
          @registered_media_types ||= {}
          @registered_media_types[@media_type] = types.shift
          if @alternate_media_types.length > types.length
            types.zip(@alternate_media_types).each{ |element| @registered_media_types[element.last] = element.first }
          else
            @alternate_media_types.zip(types).each{ |element| @registered_media_types[element.first] = element.last }
          end

          register_media_types
        end

        ##
        # Returns the media-type of the Serializer.
        #
        # @return [Symbol]
        def media_type
          @media_type ||= begin
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

        # @private
        # Subclasses self-register themselves
        def inherited(subclass)
          register_serializer(subclass.media_type, subclass)
        end
      
        private
          def register_serializer(media_type, serializer)
            Serializer.registered_serializers[media_type] = serializer
          end

          def register_media_types
            if defined?(Rails)
              @registered_media_types.each do |mime_type, content_types|
                (Mime::Type.register content_types.shift, mime_type, content_types) unless mime_type == :html

                ActionController::Renderers.add mime_type do |obj, options|
                  type = mime_type
                  obj.is_a?(Crichton::Representor) ? obj.to_media_type(type, options) : (raise TypeError, "The object #{obj.inspect} is not a Crichton::Representor. Please include in #{obj.class.name} class Crichton::Representor::State")
                end
              end
            end
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
