require 'lint/base_validator'

module Lint
  class DescriptorsValidator < BaseValidator
    VALID_MIME_TYPES = %w(html)
    #Look at Descriptor::Profile::TRANSITION_TYPES in profile.rb
    VALID_DESCRIPTOR_TRANSITIONS = %w(safe unsafe idempotent)

    def validate

      check_for_secondary_descriptor_states

      check_transition_equivalence
    end

    private
    def check_for_secondary_descriptor_states
      resource_descriptor.descriptors.each do |descriptor|
        options = {resource: resource_descriptor.name, filename: filename}

        add_error('catastrophic.no_descriptors', options) if descriptor.descriptors.empty?
        #19, check for missing doc property
        add_warning('descriptors.property_missing', options.merge({prop: 'doc'})) unless descriptor.doc

        #20, should only have a valid mime type for doc
        if descriptor.doc
          unless valid_media_type(descriptor.doc)
            add_error('descriptors.doc_media_type_invalid',options.merge({media_type: descriptor.doc.keys.last}))
          end
        end
        #21 should have a type property
        add_error('descriptors.property_missing', options.merge({prop: 'type'})) unless descriptor.type
        #22
        if descriptor.type
          unless descriptor.type == 'semantic'
            add_error('descriptors.type_invalid',options.merge({type_prop: descriptor.type}))
          end
        end

        #22 should have a link property
        add_error('descriptors.property_missing', options.merge({prop: 'link'})) unless descriptor.type_link

        #23 should have a valid link property
        if descriptor.type_link
          add_error('descriptors.link_invalid', options) unless valid_link_property(descriptor.type_link)
        end
      end
    end

    #TODO: For decorator class
    # A media type can be of text, which in case is a simple string, or a hash with specific keys with a value
    def valid_media_type(doc)
      doc.is_a?(String) || (doc.is_a?(Hash) && VALID_MIME_TYPES.include?(doc.keys.last) && !doc.values.last.nil?)
    end

    def valid_link_property(link)
      !link.attributes[:href].empty?
    end

    #61, descriptor transitions must match the transitions in the states and protocol sections
    def check_transition_equivalence
      descriptor_transitions = build_descriptor_transition_list
      #first look for protocol transitions not found in the descriptor transitions
      build_state_transition_list.each do |transition|
        unless descriptor_transitions.include?(transition)
          add_error('descriptors.state_transition_not_found', transition: transition, filename: filename)
        end
      end

      # then check if there is a transition missing for any state transition specified in the states: section
      build_protocol_transition_list.each do |transition|
        unless descriptor_transitions.include?(transition)
          add_error('descriptors.protocol_transition_not_found', transition: transition,filename: filename)
        end
      end
    end
  end
end
