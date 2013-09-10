require 'lint/base_validator'

module Lint
  class ProtocolValidator < BaseValidator

    PROTOCOL_PROPERTIES = %w(uri entry_point method content_type headers status_codes slt)

    def validate
      check_for_property_issues

      check_transition_equivalence
    end

    private

    def check_for_property_issues
      #43 we know the protocol: section exists, check to see if it has a protocol specified
      add_error('protocols.no_protocol') unless resource_descriptor.protocols

      resource_descriptor.protocols.each do |protocol_name, protocol|
        options = {protocol: protocol_name, filename: filename}

        #44 underlying protocol defined but has no content
        add_error('protocols.protocol_empty', options) if protocol.empty?

        check_for_missing_and_empty_properties(protocol, protocol_name)

        #45, single entry point per protocol
        verify_single_entry_point(protocol, protocol_name)
      end
    end

    def check_for_missing_and_empty_properties(protocol, protocol_name)
      options = {protocol: protocol_name, filename: filename}

      # only http is supported now, but future may support multiple protocols
      protocol.each do |transition_name, transition|

        # if a transition contains uri_source, then it implies an external resource...
        if transition.uri_source
          external_resource_prop_check(transition.descriptor_document, options, transition_name)
        else
          protocol_transition_prop_check(transition, options, transition_name)
        end
      end
    end

    # check if an external resource has other properties besides 'uri_source'
    def external_resource_prop_check(transition_hash, options, transition_name)
      add_warning('protocols.extraneous_props', options.merge(action: transition_name)) if has_extraneous_properties?(transition_hash)
    end

    # If a transition has 'uri_source' defined, all other properties are extraneous, since it refers to an external resource
    def has_extraneous_properties?(transition_prop_hash)
      transition_prop_hash.keys.any? { |key| PROTOCOL_PROPERTIES.include?(key.to_s) }
    end

    # Assorted checks on various properties of a protocol transition
    def protocol_transition_prop_check(transition, options, transition_name)
      #47, 48, required properties uri and method
      %w(uri method).each do |property|
        add_error('protocols.property_missing', options.merge(property: property).
          merge(action: transition_name)) unless transition.send(property)
      end

      #51, warn if status_codes is missing or if specified, any of the sub-properties are missing
      if transition.status_codes
        check_status_codes_properties(transition.status_codes, options, transition_name)
      else
        add_warning('protocols.property_missing', options.merge(property: 'status_codes').
          merge(action: transition_name))
      end

      # #49 for content_type, we check for missing, invalid content_type, and the
      # special url_source case (ok to be missing is url_source is specified)
      if transition.content_types
        # check for valid types we know of currently
        transition.content_types.each do |type|
          add_error('protocols.invalid_content_type', options.merge(content_type: type).
            merge(action: transition_name)) unless valid_content_type(type)
        end
      else
        add_error('protocols.property_missing', options.merge(property: 'content_type').
          merge(action: transition_name))
      end

      #53, slt warnings, warn if not existing, and check if it has valid child properties
      if transition.slt
        check_slt_properties(transition.slt, options, transition_name)
      else
        add_warning('protocols.property_missing', options.merge(property: 'slt').
          merge(action: transition_name)) unless transition.slt
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
    def check_status_codes_properties(status_codes, options, transition_name)
      status_codes.each do |code_name, code|
        # http codes have to be > 100
        add_warning('protocols.invalid_status_code', options.merge(code: code_name).
          merge(action: transition_name)) if options[:protocol] == 'http' && code_name.to_i < 100
        %w(description notes).each do |property|
          add_warning('protocols.missing_status_codes_property', options.merge(property: property).
            merge(action: transition_name)) unless code.keys.include?(property)
        end
      end
    end

    # If slt is defined, it should have the 3 properties below specified
    def check_slt_properties(slt, options, transition_name)
      %w(99th_percentile std_dev requests_per_second).each do |slt_prop|
        add_warning('protocols.missing_slt_property', options.merge(property: slt_prop).
          merge(action: transition_name)) unless slt.keys.include?(slt_prop)

      end
    end

    # Check to see there's one and only one entry point into the resource for a protocol
    def verify_single_entry_point(protocol, protocol_name)
      entry_point_count = 0
      protocol.values.each do |transition|
        entry_point_count += 1 if transition.entry_point
      end
      add_error('protocols.entry_point_error', error: (entry_point_count == 0) ? "No" : "Multiple",
                protocol: protocol_name, filename: filename) if entry_point_count != 1
    end

    # 54 check if the list of transitions found in the protocol section match the transitions in the
    # states and descriptor sections
    def check_transition_equivalence
      descriptors_transitions = build_descriptor_transition_list
      states_transition_list = build_state_transition_list

      resource_descriptor.protocols.each do |protocol_name, protocol|
        proto_transition_list = build_protocol_transition_list(protocol)
        #first look for protocol transitions not found in the descriptor transitions
        descriptors_transitions.each do |transition|
          add_error('protocols.descriptor_transition_not_found', transition: transition, protocol:protocol_name,
                    filename: filename) unless proto_transition_list.include?(transition)
        end

        # then check if there is a transition missing for any state transition specified in the states: section
        states_transition_list.each do |transition|
          add_error('protocols.state_transition_not_found', transition: transition, protocol: protocol_name,
                    filename: filename) unless proto_transition_list.include?(transition)
        end
      end
    end
  end
end
