module Crichton
  module Descriptors
    ## 
    # The Descriptor class is an abstract base class for descriptors.
    class Base
      ##
      # Constructs a new instance of base.
      #
      # Subclasses MUST call <tt>super</tt> in their constructors and override the <tt>type</tt> method.
      #
      # @param [Hash] descriptor_document The underlying descriptor document.
      # @param [Hash] options Optional arguments.
      # @option options [Symbol] :name Set or override the name of the descriptor.
      
      def initialize(descriptor_document, options = {})
        @descriptor_document = descriptor_document.dup
        @options = options || {}
      end
      
      ##
      # The underlying descriptor document.
      #
      # @return [Hash] The descriptor document.
      attr_reader :descriptor_document

      ##
      # The description of the descriptor.
      #
      # @return [String] The description.
      def doc
        @descriptor_document['doc']
      end
      
      ##
      # The href of the descriptor.
      #
      # @return [String] The reference.
      def href
        @descriptor_document['href']
      end

      ##
      # The name of the descriptor.
      #
      # @return [String] The name.
      def name
        @options[:name] || @descriptor_document['name']
      end
      alias :id :name

      ##
      # A sample value for the descriptor.
      #
      # @return [Object] The sample value.
      def sample
        @descriptor_document['sample']
      end

      ##
      # The return value of the descriptor.
      #
      # @return [String] The return value reference.
      def rt
        @descriptor_document['rt']
      end

      ##
      # The type of the descriptor.
      #
      # @return [String] The type.
      def type
        raise 'The method #type is an abstract method that must be overridden in subclasses.'
      end

      ##
      # The version of the descriptor.
      #
      # @return [String] The reference.
      def version
        @descriptor_document['version']
      end

      # @private
      # Overrides inspect to remove the descriptor document for readability
      def inspect
        super.gsub(/\s{,1}@descriptor_document=#{@descriptor_document.inspect}/, '')
      end
    end
  end
end
  
