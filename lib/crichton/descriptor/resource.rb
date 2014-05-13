require 'crichton/descriptor/http'
require 'crichton/descriptor/profile'
require 'crichton/descriptor/detail'
require 'crichton/descriptor/state'
require 'net/http'
require 'crichton/descriptor/descriptor_keywords'

module Crichton
  module Descriptor
    ##
    # Manages Resource Descriptor parsing and consumption for decorating service responses or interacting with
    # Hypermedia types.
    class Resource < Profile
      # The types of supported protocols.
      PROTOCOL_TYPES = %w(http)
      ##
      # Constructor
      #
      # @param [Hash] descriptor_document The section of the descriptor document representing this instance.
      def initialize(descriptor_document)
        super(self, descriptor_document)
        verify_descriptor(descriptor_document)
      end
  
      # @!macro descriptor_reader
      descriptor_reader :version
      
      ##
      # Lists the protocols defined in the descriptor document.
      #
      # @return [Array] The protocols.
      def available_protocols
        protocols.keys
      end
      
      ## 
      # The default protocol used to send messages. If not defined explicitly in the top-level of the resource 
      # descriptor document, it defaults to the first protocol defined.
      #
      # @return [String] The protocol.
      def default_protocol
        @default_protocol ||= begin
          if default_protocol = descriptor_document['default_protocol']
            default_protocol.downcase
          elsif protocol_key = protocols.keys.first
            protocol_key
          else
            raise "No protocols defined for the resource descriptor #{id}. Please define a protocol in the " <<
              "associated descriptor document or set a 'default_protocol' for the document."
          end
        end
      end

      # Returns the profile link.
      #
      # @return [Crichton::Descriptor::Link] The link.
      def profile_link
        @descriptors[:profile_link] ||= if self_link = links['profile']
        Crichton::Descriptor::Link.new(self, 'profile', self_link.absolute_href)
        end
      end

      def help_link
        @helplink ||= Crichton::Descriptor::Link.new(self, super.rel, super.absolute_href)
      end

      ##
      # Whether the specified protocol exists or not.
      #
      # @return [Boolean] <tt>true</tt> if it exists, <tt>false</tt> otherwise.
      def protocol_exists?(protocol)
        available_protocols.include?(protocol)
      end
  
      ##
      # Returns the protocol transition descriptors specified in the resource descriptor document.
      #
      # @return [Hash] The protocol transition descriptors.
      def protocols
        @descriptors[:protocol] ||= begin
          (descriptor_document['protocols'] || {}).inject({}) do |h, (protocol, protocol_transitions)|
            unless PROTOCOL_TYPES.include?(protocol)
              raise "Unknown protocol #{protocol} defined in resource descriptor document #{id}."
            end
            klass = case protocol
                    when 'http' then Http
                    end
            h[protocol] = (protocol_transitions || {}).inject({}) do |transitions, (transition, transition_descriptor)|
              transitions.tap { |hash| hash[transition] = klass.new(self, transition_descriptor, transition) }
            end
            h
          end
        end
      end
      
      ##
      # Returns a protocol-specific transition descriptor.
      #
      # @param [String] protocol The protocol name.
      # @param [String] transition_name The transition name.
      #
      # @return [Object] The descriptor instance.
      def protocol_transition(protocol, transition_name)
        protocols[protocol] && protocols[protocol][transition_name] 
      end

      ##
      # Returns the states defined for the resource descriptor.
      #
      # @return [Hash] The state instances.
      def states
        @descriptors[:state] ||= (resources || {}).inject({}) do |h,(resource, hash)|
          h[resource] = hash[Crichton::Descriptor::STATES].inject({}) do |states, (id, state_descriptor)|
            state = State.new(self, state_descriptor, id)
            states[state.name] = state
            states
          end
          h
        end.freeze
      end

      ##
      # Returns the resources defined for the resource descriptor.
      #
      # @return [Hash] The resources instances.
      def resources
        @descriptors[:resources] ||= descriptor_document[Crichton::Descriptor::TAG].select do |_, hash|
           hash[Crichton::Descriptor::STATES]
        end
      end

      ##
      # Converts the descriptor to a key for registration.
      #
      # @return [String] The key.
      def to_key
        @key ||= "#{id}"
      end

      ##
      #
      # returns an entry point for the http protocol specified for the resource
      #
      # @return [EntryPoint] Object containing entry point info
      def entry_points
        @entry_points ||= begin
          trans = protocols[:http.to_s].values.find {|tran| tran.entry_point }
          Crichton::Discovery::EntryPoint.new(trans.uri, trans.entry_point, trans.id, self.id) if trans
        end
     end

      private
      # TODO: Delegate to Lint when implemented.
      def verify_descriptor(descriptor)
        err_msg = ''
        err_msg << " missing id in #{descriptor.inspect}" unless descriptor['id']

        raise ArgumentError, 'Resource descriptor:' << err_msg unless err_msg.empty?
      end
    end
  end
end
