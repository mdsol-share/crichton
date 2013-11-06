require 'crichton/representor/serializers/xhtml'

module Crichton
  module Representor
    module Serialization
      ##
      # Manages in-line serialization of  instances.
      module MediaType
        ##
        # Returns a serialized media-type for the response, as a Hash or XML.
        #
        # @param [Symbol, String] media_type The registered media-type associated with the desired serializer.
        # @param [Hash] options Conditional options to configure to the serialization.
        def as_media_type(media_type, options = {})
          built_serializer(media_type, self, options).as_media_type(options)
        end

        def as_link(media_type, options = {})
          built_serializer(media_type, self, options).as_link(self_transition, options)
        end

        ##
        # Returns the final, serialized media-type for the response. This method differs from #as_media_type, which
        # returns a serialized object. It may be a hash or XML, for example. Serializers implement this method to 
        # convert the representation into the base media-type. For example, for a HAL JSON serializer, #as_media_type
        # would return a hash, but #to_media_type would return a JSON string.
        #
        # media_type (for now) can be :xhtml or :html
        #
        # The options hash may contain:
        #
        # :conditions => :condition
        #
        #   The conditions are defined in the states section of the descriptor document. See the
        #   {file:doc/state_descriptors.md state descriptors documentation} for more information on that topic.
        #
        # :semantics => :styled_microdata
        #
        #   semantics indicates the semantic markup type to apply. Valid options are
        #   :microdata and :styled_microdata. If not included, defaults to :microdata.
        #
        # :embed_optional => {'name1' => :embed, 'name2' => :link}
        #
        #   The keys need to be strings which correspond to the name of the attribute that has an embed: single-optional
        #   or multiple-optional or single-optional-link or multiple-optional-link. The first two embed values (the ones
        #   without -link) default to embed when no embed_optional parameter is specified, the ones with -link default
        #   to embedding a link.
        #
        # @param [Symbol, String] media_type The registered media-type associated with the desired serializer.
        # @param [Hash] options Conditional options to configure to the serialization.
        def to_media_type(media_type, options = {})
          built_serializer(media_type, self, options).to_media_type(options)
        end

        private
        def built_serializer(media_type, object, options)
          raise ArgumentError, 'The media_type argument cannot be blank.' if media_type.blank?

          # TODO: !slice serializer options related options
          Crichton::Representor::Serializer.build(media_type.to_sym, object, options)
        end
      end
    end
  end
end
