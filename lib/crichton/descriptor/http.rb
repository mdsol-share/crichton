require 'crichton/descriptor/base'
require 'crichton/descriptor/headers_decorator'
require 'addressable/template'

module Crichton
  module Descriptor
    # Manages HTTP-protocol transition descriptors.
    class Http < Base
      # @private
      RESPONSE_HEADERS = 'response_headers'

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

      # @!macro string_reader
      descriptor_reader :uri_source 

      # @!macro string_reader
      descriptor_reader :entry_point

      def transition_headers(target)
        @headers ||= (descriptor_document[RESPONSE_HEADERS] || {}).tap do |h|
          HeadersDecorator.new(h, target).to_h
        end
      end

      ##
      # Returns the url for a particular target. If the associated URI is templated, it raises an error if the
      # template variables cannot be populated from the target.
      #
      # @param [Object] target The target.
      #
      # @return [String] The fully-qualified url for the descriptor based on the target attributes.
      def url_for(target)
        if uri
          generate_populated_url(target)
        elsif target.respond_to?(uri_source)
          target.send(uri_source)
        else
          logger.warn "Crichton::Descriptor::Http.url_for doesn't have URL configured (#{target.inspect})" <<
              "Please ensure that your descriptor either has an uri attribute."
        end
      end 
      
    private
      def generate_populated_url(target)
        template = Addressable::Template.new(File.join(config.deployment_base_uri, uri))
        template.expand(mapped_template_variables(target, template)).to_s
      end
      
      def mapped_template_variables(target, template)
        mapped_variables = template.variables.inject({}) do |h, variable|
          target_attribute = target.send(variable) if target.respond_to?(variable)
          h[variable] = target_attribute if target_attribute
          h
        end
        
        missing_variables = template.variables - mapped_variables.keys
        if missing_variables.any?
          raise ArgumentError, "The target #{target.inspect} does not implement the template variable(s) " <<
            "'#{missing_variables.join(', ')}' for the '#{id}' protocol descriptor uri '#{uri}'. Check that the " <<
            "target implements the associated attribute(s) or method(s)."
        end

        mapped_variables
      end
    end
  end
end
