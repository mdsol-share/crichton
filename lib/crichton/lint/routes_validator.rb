require 'crichton/lint/base_validator'

module Crichton
  module Lint
    # class to lint the routes section of a resource descriptor document
    class RoutesValidator < BaseValidator
      section :routes

      # standard validation method
      def validate
        check_for_property_issues

        check_transition_equivalence
      end

      private
      def check_for_property_issues
        (resource_descriptor.descriptor_document['routes'] || {}).each do |route_name, hash|
          %w(controller action).each do |key|
            add_error('routes.missing_key', { resource: resource_descriptor.id, key: key, route: route_name }) if hash[key].nil?
          end
        end
      end

      def check_transition_equivalence
        protocol_transitions = build_protocol_transition_list
        routes = resource_descriptor.routes.keys

        routes.each do |route|
          unless protocol_transitions.include?(route)
            add_error('routes.missing_protocol_transitions', resource: resource_descriptor.id, route: route)
          end
        end

        protocol_transitions_without_uri_source.each do |transition|
          unless routes.include?(transition)
            add_error('routes.missing_route', resource: resource_descriptor.id, transition: transition)
          end
        end
      end

      def protocol_transitions_without_uri_source(transition_list = [])
        resource_descriptor.protocols.values.each do |protocol|
          protocol.select { |_, v| v.uri_source.nil? }.keys.each_with_object(transition_list) { |key, a| a << key unless a.include?(key) }
        end
        transition_list
      end
    end
  end
end