require 'crichton/lint/base_validator'

module Crichton
  module Lint
    # class to lint validate the protocols section of a resource descriptor document
    class ProtocolValidator < BaseValidator
      # @private list of valid protocol attributes
      PROTOCOL_PROPERTIES = %w(uri entry_point method content_type headers status_codes slt)
      section :protocols

      # standard lint validate method
      def validate
        check_for_property_issues

        check_transition_equivalence
      end

      private

      # high level validation method for errant properties
      def check_for_property_issues
        #43 we know the protocol: section exists, check to see if it has a protocol specified
        add_error('protocols.no_protocol') unless resource_descriptor.protocols

        resource_descriptor.protocols.each do |protocol_name, protocol|
          options = {protocol: protocol_name}

          #44 underlying protocol defined but has no content
          add_error('protocols.protocol_empty', options) if protocol.empty?

          check_for_missing_and_empty_properties(protocol, protocol_name)

          #45, single entry point per protocol
          verify_single_entry_point(protocol, protocol_name)
        end
      end

      # dispatches a property check based upon the uri
      def check_for_missing_and_empty_properties(protocol, protocol_name)
        options = {protocol: protocol_name}

        # only http is supported now, but future may support multiple protocols
        protocol.each do |transition_name, transition|
          # if a transition contains uri_source, then it implies an external resource...
          if transition.uri_source
            external_resource_prop_check(transition.descriptor_document, options.merge(action: transition_name))
          else
            protocol_transition_prop_check(transition, options.merge(action: transition_name))
          end
        end
      end

      # check if an external resource has other properties besides 'uri_source'
      def external_resource_prop_check(transition_hash, options)
        add_warning('protocols.extraneous_props', options) if extraneous_properties?(transition_hash)
      end

      # If a transition has 'uri_source' defined, all other properties are extraneous, since it refers to an external resource
      def extraneous_properties?(transition_prop_hash)
        transition_prop_hash.keys.any? { |key| PROTOCOL_PROPERTIES.include?(key.to_s) }
      end

      # Assorted checks on various properties of a protocol transition
      def protocol_transition_prop_check(transition, options)
        #47, 48, required properties uri and method
        %w(uri method).each do |property|
          add_error('protocols.property_missing', options.merge(property: property)) unless transition.send(property)
        end

        #51, warn if status_codes is missing or if specified, any of the sub-properties are missing
        if transition.status_codes
          check_status_codes_properties(transition.status_codes, options)
        else
          add_warning('protocols.property_missing', options.merge(property: 'status_codes'))
        end

        # #49 for content_type, we check for missing, invalid content_type, and the
        # special url_source case (ok to be missing is url_source is specified)
        if transition.content_types
          # check for valid types we know of currently
          transition.content_types.each do |type|
            add_error('protocols.invalid_content_type', options.merge(content_type: type)) unless valid_content_type(type)
          end
        else
          add_error('protocols.property_missing', options.merge(property: 'content_type'))
        end

        #53, slt warnings, warn if not existing, and check if it has valid child properties
        if transition.slt
          check_slt_properties(transition.slt, options)
        else
          add_warning('protocols.property_missing', options.merge(property: 'slt')) unless transition.slt
        end
      end

      # check if content type for a protocol transition is one of our supported types
      def valid_content_type(type)
        registered_mime_types.include?(type)
      end

      #
      # TODO: replace by calling Andrey's real method
      #
      def registered_mime_types
        %w(application/json application/hal+json application/xhtml+xml)
      end

      # for each status code key, check to see if it is a valid as per the protocol. Only have http currently.
      # Also check for description and notes sub-properties
      def check_status_codes_properties(status_codes, options)
        status_codes.each do |code_name, code|
          # http codes have to be > 100
          if options[:protocol] == 'http' && code_name.to_i < 100
            add_warning('protocols.invalid_status_code', options.merge(code: code_name))
          end
          %w(description notes).each do |property|
            unless code.keys.include?(property)
              add_warning('protocols.missing_status_codes_property', options.merge(property: property))
            end
          end
        end
      end

      # If slt is defined, it should have the 3 properties below specified
      def check_slt_properties(slt, options)
        %w(99th_percentile std_dev requests_per_second).each do |slt_prop|
          unless slt.keys.include?(slt_prop)
            add_warning('protocols.missing_slt_property', options.merge(property: slt_prop))
          end
        end
      end

      # Check to see there's one and only one entry point into the resource for a protocol
      def verify_single_entry_point(protocol, protocol_name)
        entry_point_count = protocol.values.inject(0) { |i, transition| transition.entry_point ? i + 1 : i }
        unless entry_point_count == 1
          add_error('protocols.entry_point_error', error: entry_point_count == 0 ? "No" : "Multiple",
            protocol: protocol_name)
        end
      end

      # 54 check if the list of transitions found in the protocol section match the transitions in the
      # states and descriptor sections
      def check_transition_equivalence
        protocol_transition_list = build_protocol_transition_list

        #first look for protocol transitions not found in the descriptor transitions
        build_descriptor_transition_list.each do |transition|
          unless protocol_transition_list.include?(transition)
            add_error('protocols.descriptor_transition_not_found', transition: transition)
          end
        end

        # then check if there is a transition missing for any state transition specified in the states: section
        build_state_transition_list.each do |transition|
          unless protocol_transition_list.include?(transition)
            add_error('protocols.state_transition_not_found', transition: transition)
          end
        end
      end
    end
  end
end
