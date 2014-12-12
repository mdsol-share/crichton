require 'crichton/descriptor/base'
require 'addressable/template'

module Crichton
  module Descriptor
    # Manages HTTP-protocol transition descriptors.
    class Http < Base
      # @!macro array_reader
      descriptor_reader :content_types

      # @!macro array_reader
      descriptor_reader :headers

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
          logger.warn "Crichton::Descriptor::Http.url_for class (#{target}) does not implement the 'uri' or 'uri_source' methods"
        end
      end

      def interface_method
        uri_source ? 'GET' : descriptor_document['method']
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
