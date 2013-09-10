require 'crichton'
require 'lint'
require 'i18n'

module Lint
  class BaseValidator

    attr_reader :errors
    attr_reader :warnings
    attr_reader :resource_descriptor
    attr_reader :filename

    def initialize(resource_descriptor, filename)
      @warnings = []
      @errors = []
      @filename = filename
      @resource_descriptor = resource_descriptor
    end

    #When the dust settles, print out the results of the lint analysis
    def report
      errors.each { |error| puts "\tERROR: " << error }
      warnings.each { |warning| puts "\tWARNING: " << warning }
    end

    def validate(options = {})
      raise "Abstract method #validate must be overridden in #{self.class.name}."
    end

    def issues?
      errors.any? || warnings.any?
    end

    protected
    def add_error(message, options = {})
      @errors << I18n.t(message, options)
    end

    def add_warning(message, options = {})
      @warnings << I18n.t(message, options)
    end

    def secondary_descriptors
      resource_descriptor.descriptors
    end

    # used by subclasses to perform transition equivalency tests
    def build_descriptor_transition_list
      transition_list = find_descriptor_transitions(@resource_descriptor.descriptors, [])
    end

    def find_descriptor_transitions(descriptors, transition_list)
      descriptors.each do |descriptor|
        transition_list << descriptor.id if descriptor.transition?
        find_descriptor_transitions(descriptor.descriptors, transition_list) if descriptor.descriptors
      end
      transition_list
    end

    def build_protocol_transition_list(protocol = nil)
      protocol ||= @resource_descriptor.protocols.first
      protocol.inject([]) { |a, protocol_obj| a << protocol_obj.first }
    end

    def build_state_transition_list
      transition_list = []
      resource_descriptor.states.values.each do |secondary_descriptor|
         secondary_descriptor.values.each do |state|
            state.transitions.keys.each do |transition|
             transition_list << transition unless transition_list.include?(transition[0])
           end
         end
       end
      transition_list
    end
  end
end

