require 'crichton/representor/serializers/representor_serializer'
require 'crichton/representor/serializers/xhtml'
require 'crichton/representor/serializers/hale_json'
require 'crichton/representor/serializers/hal_json'

module Crichton
  module Representor
    module Serialization
      ##
      # Manages in-line serialization of  instances.
      module MediaType
        ##
        # Returns the final, serialized media-type for the response. This method differs from #as_media_type, which
        # returns a serialized object. It may be a hash or XML, for example. Serializers implement this method to 
        # convert the representation into the base media-type. For example, for a HAL JSON serializer, #as_media_type
        # would return a hash, but #to_media_type would return a JSON string.
        #
        # For documentation of options, see {file:doc/getting_started.md Getting Started}
        #
        # @param [Symbol, String] media_type The registered media-type associated with the desired serializer.
        # @param [Hash] options Conditional options to configure to the serialization.
        # @option options [String, Symbol, Array] :conditions The state conditions.
        # @option options [String, Symbol, Array] :except The semantic data descriptor names to filter out.
        # @option options [String, Symbol, Array] :only The semantic data descriptor names to limit.
        # @option options [String, Symbol, Array] :include The embedded semantic descriptor names to include.
        # @option options [String, Symbol, Array] :exclude The embedded semantic descriptor names to exclude.
        # @option options [String, Symbol, Array] :additional_links Allows dynamically adding new links.
        # @option options [String, Symbol, Array] :override_links Allow overriding the URL set in links.
        # @option options [String, Symbol, Array] :state The state of the resource.
        def to_representor(options)
          serializer = Crichton::Representor::RepresentorSerializer.new(self, options)
          serializer.to_representor(options)
        end

        def respond_to?(method, include_private = false)
          super || if (match = method.to_s.match(/^to_(\w*)$/))
            registered?(match[1].to_sym)
          end
        end

        def as_media_type(media_type, options={})
          if media_type == :xhtml #TODO: Remove when Representor serializer XHTML
            built_serializer(media_type, self, options).as_media_type(options)
          else
            serializer = Crichton::Representor::RepresentorSerializer.new(self, options)
            serializer.as_media_type(options)
          end
        end

        def to_media_type(media_type, options={})
          if media_type == :xhtml #TODO: Remove when Representor serializer XHTML
            as_media_type(media_type, options)
          else
            Representors::Representor.new(as_media_type(media_type, options)).to_media_type(media_type, options)
          end
        end
        
        # @deprecated
        def as_link(media_type, options = {}) # TODO: remove when Representor serializer XHTML
          built_serializer(media_type, self, options).as_link(self_transition, options)
        end

        # @deprecated
        def built_serializer(media_type, object, options) # TODO: remove when Representor serializer XHTML
          raise ArgumentError, 'The media_type argument cannot be blank.' if media_type.blank?
          
          Crichton::Representor::Serializer.build(media_type.to_sym, object, options)
        end

        def method_missing(method, *args, &block)
          if (match = method.to_s.match(/^to_(\w*)$/))
            type = match[1].to_sym
            if registered?(type)
              to_media_type(type, *args, &block)
            else
              raise NameError, "#{method} is not defined for #{self} and #{type} is not a registered media-type"
            end
          else
            super
          end
        end

        #TODO: Should use representors
        def registered?(type)
          Crichton::Representor::Serializer.serializer?(type)
        end

      end
    end
  end
end
