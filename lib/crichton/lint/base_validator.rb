require 'crichton'
require 'crichton/lint'
require 'i18n'
require 'colorize'

module Crichton
  module Lint
    # Base class for all lint validator classes
    class BaseValidator

      # @attr_reader [Array] errors
      attr_reader :errors

      # @attr_reader [Array] warnings
       attr_reader :warnings

      # @attr_reader [Crichton::Descriptor::Resource] resource_descriptor
      attr_reader :resource_descriptor

      # @attr_reader [String] filename
      attr_reader :filename

      ##
      # Constructor
      #
      # @param [Crichton::Descriptor::Resource] resource_descriptor main Crichton object containing Crichton elements
      # @param [String] filename name of the file used in the linting process
      # @param [Hash] options lint options when invoking lint
      def initialize(resource_descriptor, filename, options)
        @warnings = []
        @errors = []
        @filename = filename
        @resource_descriptor = resource_descriptor
        @options = options
      end

      #When the dust settles, print out the results of the lint analysis, unless strict mode, which returns true / false
      def report
        output_sub_header unless class_section == :catastrophic
        puts "ERRORS:".red if errors.any?
        errors.each { |error| puts "  #{error.red}\t" }
        unless @options[:no_warnings]
          puts "WARNINGS:".yellow  if warnings.any?
          warnings.each { |warning| puts "  #{warning.yellow}\t" }
        end
      end

      # outputs one of several sub headers, each associated with a top level section in the resource descriptor file
      def output_sub_header
        if errors.any?
           puts "\n#{class_section.capitalize} Section:"
        else
          unless @options[:no_warnings]
            puts "\n#{class_section.capitalize} Section:" if warnings.any?
          end
         end
      end

      # base class method that must be overridden by child classes
      def validate(options = {})
        raise "Abstract method #validate must be overridden in #{self.class.name}."
      end

      # @return [Boolean] true if there are any warnings or errors, false if not
      def issues?
        errors.any? || warnings.any?
      end

      # returns [Integer] the number of errors found
      def error_count
        @errors.count
      end

     # returns [Integer] the number of warnings found
      def warning_count
        @warnings.count
      end

      ##
      # @param [String] message the message string to be added to the error list
      # @param [Hash] options additional key value pairs to complete the total message
      def add_error(message, options = {})
        @errors << I18n.t(message, options)
      end

      ##
      # @param [String] message the message string to be added to the error list
      # @param [Hash] options additional key value pairs to complete the total message
      def add_warning(message, options = {})
        @warnings << I18n.t(message, options)
      end

      protected

      # @return [Array] a list of resources in the linted file
      def secondary_descriptors
        resource_descriptor.descriptors
      end

      # used by subclasses to perform transition equivalency tests
      def build_descriptor_transition_list
        find_descriptor_transitions(@resource_descriptor.resources, [])
      end

      ##
      # Recursive method to walk the descriptor chain in order to find transition descriptors
      #
      # @param [Array] descriptors the list of descriptors at the current level of recursion
      # @param [Array] transition_list list being built up containing the list of transition descriptor ids
      def find_descriptor_transitions(descriptors, transition_list)
        descriptors.inject(transition_list) do |a, descriptor|
          a << descriptor.id if descriptor.transition?
          descriptor.descriptors ? find_descriptor_transitions(descriptor.descriptors, a) : a
        end
      end

      ##
      # Builds a list of transitions found in the protocol section of a resource descriptor document
      #
      # @param [Array] transition_list supplied list object to fill in the list of transition keys
      # @return [Array] list of protocol transition keys
      def build_protocol_transition_list(transition_list = [])
        resource_descriptor.protocols.values.each do |protocol|
          protocol.keys.each_with_object(transition_list) { |key, a| a << key unless a.include?(key) }
        end
        transition_list
      end

      ##
      # Builds a list of transitions found in the states section of a resource descriptor document
      #
      # @param [Array] transition_list supplied list object to fill in the list of transition keys
      # @return [Array] list of state transition keys
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
