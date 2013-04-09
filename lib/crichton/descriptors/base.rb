module Crichton
  ## 
  # The BaseDescriptor class is an abstract base class for descriptors.
  class BaseDescriptor
    # @private
    EXCLUDED_VARIABLES = %w(@descriptor_document @protocol_descriptors @resource_descriptor).map(&:to_sym)
        
    ##
    # Constructs a new instance of base.
    #
    # Subclasses MUST call <tt>super</tt> in their constructors and override the <tt>type</tt> method.
    #
    # @param [Hash] descriptor_document The section of the descriptor document representing this instance.
    # @param [Hash] options Optional arguments.
    # @option options [Symbol] :id Set or override the id of the descriptor.
    def initialize(descriptor_document, options = {})
      @descriptor_document = descriptor_document && descriptor_document.dup || {}
      @options = options || {}
      @id = @options[:id]
    end
    
    ##
    # The underlying descriptor document.
    #
    # @return [Hash] The descriptor document.
    attr_reader :descriptor_document
    
    ##
    # The id of the descriptor.
    #
    # @return [String] The id.
    def id
      @id ||= descriptor_document['id']
    end

    ##
    # The description of the descriptor.
    #
    # @return [String] The description.
    def doc
      descriptor_document['doc']
    end
    
    ##
    # The descriptor links.
    #
    # @return [Array] The LinkDescriptor objects.
    def links
      @links ||= (descriptor_document['links'] || {}).map { |rel, href| LinkDescriptor.new(rel, href) }
    end
    
    ##
    # The href of the descriptor.
    #
    # @return [String] The reference.
    def href
      descriptor_document['href']
    end

    ##
    # The name of the descriptor.
    #
    # @return [String] The name.
    def name
      descriptor_document['name']
    end

    ##
    # The type of the descriptor.
    #
    # @return [String] The type.
    def type
      raise 'The method #type is an abstract method that must be overridden in subclasses.'
    end

    # @private
    # Overrides inspect to remove the descriptor document for readability
    def inspect
      ivars = (instance_variables - EXCLUDED_VARIABLES).map do |ivar|
        "#{ivar}=#{instance_variable_get(ivar).inspect}"
      end
      '#<%s:0x%s %s>' % [self.class.name, self.hash.to_s(16), ivars.join(", ")]
    end
  end
end
