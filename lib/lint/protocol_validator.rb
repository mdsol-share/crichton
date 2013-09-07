require 'lint/base_validator'

module Lint
  class ProtocolValidator < BaseValidator

    def validate
      check_for_property_issues

      check_transition_equivalence
    end

    private

    def check_for_property_issues
      #43 we know the protocol: section exists, check to see if it has a protocol specified
      add_error('protocols.no_protocol') unless resource_descriptor.protocols

      resource_descriptor.protocols.each do |protocol_obj|
        options = {protocol: protocol_obj[0], filename: filename}

        protocol = protocol_obj[1]
        #44 underlying protocol defined but has no content
        add_error('protocols.protocol_empty', options) if protocol.empty?

        check_for_missing_and_empty_properties(protocol, protocol_obj[0])

        #45, single entry point per protocol
        verify_single_entry_point(protocol, protocol_obj[0])
      end
    end

    def check_for_missing_and_empty_properties(protocol, protocol_name)
      options = {protocol: protocol_name, filename: filename}

      # only http is supported now, but future may support multiple protocols
      protocol.each do |action_obj|
        action = action_obj[1]

        # if an action contains uri_source, then it implies an external resource...
        if action.uri_source
          external_resource_prop_check(action.descriptor_document, options, action_obj[0])
        else
          resource_action_prop_check(action, options, action_obj[0])
        end
      end
    end

    # check if an external resource has other properties besides 'uri_source'
    def external_resource_prop_check(action_hash, options, action_name)
      add_warning('protocols.extraneous_props', options.merge(action: action_name)) if has_extraneous_properties?(action_hash)
    end

    # If action has uri_source defined, all other properties are extraneous, since it refers to an external resource
    def has_extraneous_properties?(action_prop_hash)
      potential_props = %w(uri entry_point method content_type headers status_codes slt)
      action_prop_hash.keys.any? { |key| potential_props.include?(key.to_s) }
    end

    # Assorted checks on various properties of a protocol action
    def resource_action_prop_check(action, options, action_name)
      #47, 48, required properties uri and method
      %w(uri method).each do |property|
        add_error('protocols.property_missing', options.merge(property: property).
          merge(action: action_name)) unless action.send(property)
      end

      #51, warn if status_codes is missing or if specified, any of the sub-properties are missing
      if action.status_codes
        check_status_codes_properties(action.status_codes, options, action_name)
      else
        add_warning('protocols.property_missing', options.merge(property: 'status_codes').
          merge(action: action_name))
      end

      # #49 for content_type, we check for missing, invalid content_type, and the
      # special url_source case (ok to be missing is url_source is specified)
      if action.content_types
        # check for valid types we know of currently
        action.content_types.each do |type|
          add_error('protocols.invalid_content_type', options.merge(content_type: type).
            merge(action: action_name)) unless valid_content_type(type)
        end
      else
        add_error('protocols.property_missing', options.merge(property: 'content_type').
          merge(action: action_name))
      end

      #53, slt warnings, warn if not existing, and check if it has valid child properties
      if action.slt
        check_slt_properties(action.slt, options, action_name)
      else
        add_warning('protocols.property_missing', options.merge(property: 'slt').
          merge(action: action_name)) unless action.slt
      end
    end

    # check if content type for an action is one of our supported types
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
    def check_status_codes_properties(status_codes, options, action_name)
      status_codes.each do |code|
        # http codes have to be > 100
        add_warning('protocols.invalid_status_code', options.merge(code: code[0]).
          merge(action: action_name)) if options[:protocol] == 'http' && code[0].to_i < 100
        %w(description notes).each do |property|
          add_warning('protocols.missing_status_codes_property', options.merge(property: property).
            merge(action: action_name)) unless code[1].keys.include?(property)
        end
      end
    end

    # If slt is defined, it should have the 3 properties below specified
    def check_slt_properties(slt, options, action_name)
      %w(99th_percentile std_dev requests_per_second).each do |slt_prop|
        add_warning('protocols.missing_slt_property', options.merge(property: slt_prop).
          merge(action: action_name)) unless slt.keys.include?(slt_prop)

      end
    end

    # Check to see there's one and only one entry point into the resource for a protocol
    def verify_single_entry_point(protocol, protocol_name)
      entry_point_count = 0
      protocol.each do |action|
        entry_point_count += 1 if action[1].entry_point
      end
      add_error('protocols.entry_point_error', error: (entry_point_count == 0) ? "No" : "Multiple",
                protocol: protocol_name, filename: filename) if entry_point_count != 1
    end

    # 54 check if the list of actions found in the protocol section match the transitions in the
    # states and descriptor sections
    def check_transition_equivalence
      descriptors_transitions = build_descriptor_transition_list
      states_transition_list = build_state_transition_list

      resource_descriptor.protocols.each do |protocol_obj|
        action_list = build_action_list(protocol_obj[1])
        #first look for actions not found in the descriptor transitions
        descriptors_transitions.each do |transition|
          add_error('protocols.descriptor_transition_not_found', transition: transition, protocol: protocol_obj[0],
                    filename: filename) unless action_list.include?(transition)
        end

        # then check if there is an action missing for any state transition specified in the states: section
        states_transition_list.each do |transition|
          add_error('protocols.state_transition_not_found', transition: transition, protocol: protocol_obj[0],
                    filename: filename) unless action_list.include?(transition)
        end
      end
    end
  end
end
