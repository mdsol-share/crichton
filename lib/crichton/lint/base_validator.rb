require 'crichton'
require 'crichton/lint'
require 'i18n'
require 'colorize'

module Crichton
  module Lint
    class BaseValidator

      attr_reader :errors
      attr_reader :warnings
      attr_reader :resource_descriptor
      attr_reader :filename

      def initialize(resource_descriptor, filename, options)
        @warnings = []
        @errors = []
        @filename = filename
        @resource_descriptor = resource_descriptor
        @options = options
      end

      #When the dust settles, print out the results of the lint analysis, unless strict mode, which returns true / false
      def report
        if @options[:strict]
          errors.empty?
        else
          output_sub_header unless class_section == :catastrophic
          puts "ERRORS:".red if errors.any?
          errors.each { |error| puts "  #{error.red}\t" }
          unless @options[:no_warnings]
            puts "WARNINGS:".yellow  if warnings.any?
            warnings.each { |warning| puts "  #{warning.yellow}\t" }
          end
        end
      end

      def output_sub_header
        if errors.any?
           puts "\n#{class_section.capitalize} Section:"
        else
          unless @options[:no_warnings]
            puts "\n#{class_section.capitalize} Section:" if warnings.any?
          end
         end
      end

      def validate(options = {})
        raise "Abstract method #validate must be overridden in #{self.class.name}."
      end

      def issues?
        errors.any? || warnings.any?
      end

      def error_count
        @errors.count
      end

      def warning_count
        @warnings.count
      end

      def add_error(message, options = {})
        @errors << I18n.t(message, options)
      end

      def add_warning(message, options = {})
        @warnings << I18n.t(message, options)
      end

      protected
      def secondary_descriptors
        resource_descriptor.descriptors
      end

      # used by subclasses to perform transition equivalency tests
      def build_descriptor_transition_list
        find_descriptor_transitions(@resource_descriptor.descriptors, [])
      end

      def find_descriptor_transitions(descriptors, transition_list)
        descriptors.inject(transition_list) do |a, descriptor|
          a << descriptor.id if descriptor.transition?
          descriptor.descriptors ? find_descriptor_transitions(descriptor.descriptors, a) : a
        end
      end

      def build_protocol_transition_list(transition_list = [])
        resource_descriptor.protocols.values.each do |protocol|
          protocol.keys.each_with_object(transition_list) { |key, a| a << key unless a.include?(key) }
        end
        transition_list
      end

      def build_state_transition_list(transition_list = [])
        resource_descriptor.states.values.each do |secondary_descriptor|
          secondary_descriptor.values.each do |state|
            state.transitions.keys.each_with_object(transition_list) { |key, a| a << key unless a.include?(key) }
          end
        end
        transition_list
      end

      def self.section(section)
        @section = section
      end

      def class_section
        self.class.instance_variable_get(:@section)
      end
    end
  end
end
