require 'crichton/lint/base_validator'
require 'crichton/lint/embed_validator'
require 'crichton/lint/field_type_validator'
require 'crichton/lint/options_validator'

# base class for all lint validators
module Crichton
  module Lint
    # class to lint the descriptors section of a resource descriptor document
    class DescriptorsValidator < BaseValidator
      # @private used when walking a descriptor object graph. Different rules apply with respect to level within the groph
      TOP_LEVEL = 0
      # @private only html is a valid mime type
      VALID_MIME_TYPES = %w(html)

      section :descriptors

      # standard validation method
      def validate
        check_descriptor_graph

        compare_with_state_resources

        check_id_uniqueness

        check_transition_equivalence
      end

      private

      # begins a walk-down through the graph of descriptors
      def check_descriptor_graph
        check_descriptor_level(@resource_descriptor.resources, {}, TOP_LEVEL)
      end

      # recursive method to dispatch to a variety of checks
      def check_descriptor_level(descriptors, options, level)
        descriptors.each do |descriptor|
          options = {resource: descriptor.id}
          descriptor_properties_check(descriptor, options, level)
          unless descriptor.descriptors.empty?
            child_transition_check(descriptor, options) if descriptor.transition?
            check_descriptor_level(descriptor.descriptors, options, level + 1)
          end
        end
      end

      # check for child transition of a transition descriptor
      def child_transition_check(descriptor, options)
        if descriptor.descriptors.any? { |desc| desc.transition? }
          add_error('descriptors.invalid_child_transition', options.merge({id: descriptor.id}))
        end
      end

      # do checks for the properties common to both semantic and transition type descriptors
      def descriptor_properties_check(descriptor, options, level)
        common_properties_check(descriptor, options, level)
        semantic_properties_check(descriptor, options, level) if descriptor.semantic?
        transition_properties_check(descriptor, options, level) if descriptor.transition?
      end

      # performs a variety of error/warning checks for descriptors
      def common_properties_check(descriptor, options, level)
        #20, should have a valid mime type for doc property
        if descriptor.doc
          unless valid_media_type?(descriptor.doc)
            add_error('descriptors.doc_media_type_invalid', options.merge({media_type: descriptor.doc.keys.last}))
          end
        else
          #19, check for missing doc property
          add_error('descriptors.property_missing', options.merge({prop: 'doc'}))
        end

        #22
        if descriptor.type
          unless Crichton::Descriptor::Profile::DESCRIPTOR_TYPES.include?(descriptor.type)
            add_error('descriptors.type_invalid', options.merge({type_prop: descriptor.type}))
          end
        else
          #21 should have a type property
          add_error('descriptors.property_missing', options.merge({prop: 'type'}))
        end

        if resource_descriptor.resources.map{ |resource| resource.name }.include?(descriptor.name)
          add_error('catastrophic.no_descriptors', options) if descriptor.descriptors.empty?

          #23 should have a valid link property
          if descriptor.links.empty?
            #22 should have a link property
            add_warning('descriptors.property_missing', options.merge({prop: 'link'}))
          else
            unless valid_link_property?(descriptor.link['profile'])
              add_error('descriptors.link_invalid', options.merge({link: descriptor.link.keys.first}))
            end
          end
        end
      end

      #TODO: For decorator class
      # A media type can be of text, which in case is a simple string, or a hash with specific keys with a value
      def valid_media_type?(doc)
        doc.is_a?(String) || (doc.is_a?(Hash) && VALID_MIME_TYPES.include?(doc.keys.last) && doc.values.last)
      end

      def valid_link_property?(link)
        link && !link.attributes[:href].empty?
      end

      # check all rules surrounding transition based descriptors
      def semantic_properties_check(descriptor, options, level)
        if level > TOP_LEVEL
          FieldTypeValidator.validate(self, descriptor)
          EmbedValidator.validate(self, descriptor)
          OptionsValidator.validate(self, descriptor)

          # all NON top level descriptors should have a sample and href entry
          add_warning('descriptors.property_missing', options.merge({prop: 'sample'})) unless descriptor.sample
          add_warning('descriptors.property_missing', options.merge({prop: 'href'})) unless descriptor.href
        end
      end

      # check all rules surrounding transition based descriptors
      def transition_properties_check(descriptor, options, level)
        if level > TOP_LEVEL
          # all NON top level descriptors should have a rt (return type) property
          if descriptor.rt
            # check if the return type is a valid local type to this file or an external return type
            unless valid_return_type(descriptor.rt)
              add_error('descriptors.invalid_return_type', options.merge({rt: descriptor.rt}))
            end
          else
            add_error('descriptors.missing_return_type', options)
          end
          check_protocol_method_and_type(descriptor.type, descriptor.decorate(self).interface_method, options)
        end
      end

      # if an external return type, assume http as only valid external for now
      def valid_return_type(return_type)
        return true if  Crichton::Descriptor::Resource::PROTOCOL_TYPES.include?(return_type[/\Ahttp/])
        return true if return_type.downcase == 'none'
        rt_is_a_valid_subresource(return_type)
      end

      def rt_is_a_valid_subresource(return_type)
        resource_descriptor.states.include?(return_type)
      end

      # check for method consistency if descriptor type matches the proper ReSTful method
      def check_protocol_method_and_type(type, method, options)
        case type.to_sym
          when :safe
            if %w(PUT POST DELETE).include?(method)
              add_error('descriptors.invalid_method', options.merge({mthd: method, type: type}))
            end
          when :unsafe
            add_error('descriptors.invalid_method', options.merge({mthd: method, type: type})) unless method == 'POST'
          when :idempotent
            add_error('descriptors.invalid_method', options.merge({mthd: method, type: type})) if method == 'GET'
        end
      end

      #60, the descriptor hash of subresources must equal the state hash
      def compare_with_state_resources
        # TODO: change descriptor array into a hash with name as keys, or convert state names to an array of names
        compare_with_other_hash(resource_descriptor.resources.map { |resource| resource.name }, resource_descriptor.states.keys,
          'descriptors.descriptor_resource_not_found')
        compare_with_other_hash(resource_descriptor.states.keys, resource_descriptor.resources.map { |resource| resource.name },
          'descriptors.state_resource_not_found')
      end

      def compare_with_other_hash(base_resources, others_resources, error)
        base_resources.each do |resource_name|
          add_error(error, resource: resource_name) unless others_resources.include?(resource_name)
        end
      end

      # starter method to walk the chain to look for duplicate ids
      def check_id_uniqueness
        review_descriptor_ids(@resource_descriptor.descriptors, resource_descriptor.id, {})
      end

      # recursive method to perform id checks
      def review_descriptor_ids(descriptors, parent_id, id_hash)
        descriptors.each do |descriptor|
          add_error('descriptors.non_unique_descriptor', id: descriptor.id, parent: parent_id) if id_hash[descriptor.id]
          key = "#{parent_id}/#{descriptor.id}"
          id_hash[key] = descriptor.id unless id_hash[key]
          review_descriptor_ids(descriptor.descriptors, key, id_hash) if descriptor.descriptors
        end
      end

      #61, descriptor transitions must match the transitions in the states and protocol sections
      def check_transition_equivalence
        descriptor_transitions = build_descriptor_transition_list
        #first look for protocol transitions not found in the descriptor transitions
        build_state_transition_list.each do |transition|
          unless descriptor_transitions.include?(transition)
            add_error('descriptors.state_transition_not_found', transition: transition)
          end
        end

        # then check if there is a transition missing for any state transition specified in the states: section
        build_protocol_transition_list.each do |transition|
          unless descriptor_transitions.include?(transition)
            add_error('descriptors.protocol_transition_not_found', transition: transition)
          end
        end
      end
    end
  end
end
