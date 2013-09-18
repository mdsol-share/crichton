require 'spec_helper'

module Crichton
  describe Representor do
    let(:simple_test_class) do 
      resource_name = @resource_name
      class_state_method = @state_method
      include_state = @include_state
      Class.new do
        include class_state_method || include_state ? Representor::State : Representor
        
        represents resource_name if resource_name
        state_method class_state_method if class_state_method
        
        def initialize(attributes = {})
          @attributes = attributes.stringify_keys if attributes
        end
        
        attr_accessor :attributes
        
        # Use method missing/respond_to to mimic accessors
        def method_missing(method, *args, &block)
          (attributes && attributes.keys.include?(method.to_s)) ? attributes[method.to_s] : super
        end
        
        def respond_to?(method)
          (attributes && attributes.keys.include?(method.to_s)) ? true : super
        end
      end
    end
    
    it 'acts as a media-type serializer' do
      simple_test_class.new.should be_a(Representor::Serialization::MediaType)
    end
    
    context 'with associated class-level descriptors' do
      before do
        @resource_name = 'drds'
        Crichton.initialize_registry(drds_descriptor)
      end
      
      describe '.data_semantic_descriptors' do
        it 'returns the filtered list of semantic data descriptors' do
          simple_test_class.data_semantic_descriptors.map(&:name).should == %w(total_count)
        end
      end

      describe '.embedded_semantic_descriptors' do
        it 'returns the filtered list of semantic embedded descriptors' do
          simple_test_class.embedded_semantic_descriptors.map(&:name).should == %w(items)
        end
      end

      describe '.link_transition_descriptors' do
        it 'returns the filtered list of link transition descriptors mapped by name' do
          simple_test_class.link_transition_descriptors.first.name.should == 'self'
        end
      end

      describe '.embedded_transition_descriptors' do
        it 'returns the filtered list of embedded transition descriptors' do
          @resource_name = 'drd'
          simple_test_class.embedded_transition_descriptors.first.name.should == 'leviathan'
        end
      end
    end
    
    describe '.represents' do
      it 'sets the resource name of the represented resource' do
        simple_test_class.represents :some_resource
        simple_test_class.resource_name.should == 'some_resource'
      end
    end
    
    describe '.resource_descriptor' do
      it 'raises an error if no resource name has been defined for the class' do
        Crichton.stub(:descriptor_registry).and_return({})
        Crichton.stub(:config_directory).and_return(resource_descriptor_fixtures)
        expect { simple_test_class.resource_descriptor }.to raise_error(Crichton::RepresentorError,
          /^No resource name has been defined.*/)
      end
      
      it 'returns the resource descriptor registered with the resource name' do
        resource_descriptor = mock('resource_descriptor')
        @resource_name = 'resource'
        Crichton.stub(:descriptor_registry).and_return(@resource_name => resource_descriptor)
        
        simple_test_class.resource_descriptor.should == resource_descriptor
      end
    end
    
    describe '.resource_name' do
      it 'raises an error if no resource name has been defined for the class' do
        expect { simple_test_class.resource_name }.to raise_error(Crichton::RepresentorError,
          /^No resource name has been defined.*/)
      end
      
      it 'returns the resource name set on the base class' do
        @resource_name = :resource
        simple_test_class.resource_name.should == 'resource'
      end
    end

    context 'with_registered resource descriptor' do
      before do
        Crichton.initialize_registry(drds_descriptor)
      end

      describe '#each_data_semantic' do
        let(:data_semantics) do
          simple_test_class.new(@attributes).each_data_semantic(@options).inject({}) do |h, descriptor| 
            h.tap { |hash| hash[descriptor.name] = descriptor }
          end
        end
        
        before do
          @resource_name = 'drd'
          @attributes = {'uuid' => 'representor_uuid', 'name' => 'representor'}
        end
        
        it 'returns an enumerator' do
          simple_test_class.new.each_data_semantic.should be_a(Enumerable)
        end

        it 'yields decorated semantic descriptors' do
          simple_test_class.new(@attributes).each_data_semantic.all? do |item| 
            item.instance_of?(Crichton::Descriptor::SemanticDecorator)
          end
        end

        it 'raises an error if options are passed that are not a hash' do
          expect { simple_test_class.new.each_data_semantic('options').to_a }.to raise_error(ArgumentError,
            /options must be nil or a hash. Received '"options"'./)
        end
        
        it 'returns only semantic descriptors whose source exists' do
          @attributes.each { |k, v| data_semantics[k].value.should == v }
        end
        
        it 'excludes semantic descriptors that do not exist on the representor instance' do
          data_semantics['status'].should be_nil
        end
        
        context 'with :only option' do
          before do
            @options = {only: :uuid}
          end
          
          it 'returns the specified semantic descriptors' do
            data_semantics['uuid'].should_not be_nil
          end

          it 'excludes all other semantic descriptors' do
            data_semantics['name'].should be_nil
          end
        end

        context 'with :except option' do
          before do
            @options = {except: :uuid}
          end
          
          it 'excludes all specified semantic descriptors' do
            data_semantics['uuid'].should be_nil
          end

          it 'returns all other semantic descriptors' do
            data_semantics['name'].should_not be_nil
          end
        end
      end
      
      describe '#each_embedded_semantic' do
        let(:embedded_semantics) do
          simple_test_class.new(@attributes).each_embedded_semantic(@options).inject({}) do |h, descriptor|
            h.tap { |hash| hash[descriptor.name] = descriptor }
          end
        end

        before do
          @resource_name = 'drds'
          @item = mock('item')
          @attributes = {'items' => [@item]}
        end

        it 'returns an enumerator' do
          simple_test_class.new.each_data_semantic.should be_a(Enumerable)
        end

        it 'yields decorated semantic descriptors' do
          simple_test_class.new(@attributes).each_embedded_semantic.all? do |item|
            item.instance_of?(Crichton::Descriptor::SemanticDecorator)
          end
        end
        
        it 'raises an error if options are passed that are not a hash' do
          expect { simple_test_class.new.each_embedded_semantic('options').to_a }.to raise_error(ArgumentError,
            /options must be nil or a hash. Received '"options"'./)
        end
        
        it 'returns only semantic descriptors whose source exists' do
          embedded_semantics['items'].value.should == [@item]
        end

        context 'with :include option' do
          it 'returns only the specified semantic descriptors' do
            @options = {include: :items}
            embedded_semantics['items'].should_not be_nil
          end
        end

        context 'with :except option' do
          it 'returns all the semantic descriptors that were not excluded' do
            @options = {exclude: :items}
            embedded_semantics['items'].should be_nil
          end
        end
      end

      let(:options) do
        (@options || {}).tap do |options|
          options[:state] = @state
          options[:conditions] = @conditions
          options[:additional_links] = @additional_links if @additional_links
          # Yes, I want the .nil? as this could be true or false
          options[:top_level] = @top_level unless @top_level.nil?
        end
      end

      describe '#each_embedded_transition' do
        let(:embedded_transitions) do
          simple_test_class.new(@attributes).each_embedded_transition(options).inject({}) do |h, descriptor|
            h.tap { |hash| hash[descriptor.id] = descriptor }
          end
        end

        before do
          @resource_name = 'drd'
        end

        it 'returns an enumerator' do
          simple_test_class.new.each_link_transition.should be_a(Enumerable)
        end

        it 'yields decorated transition descriptors' do
          simple_test_class.new.each_embedded_transition.all? do |item|
            item.instance_of?(Crichton::Descriptor::TransitionDecorator)
          end
        end

        it 'yields the additional links' do
          @top_level = true
          @additional_links = {'first' => 'first_link', 'second' => 'second_link'}
          results = []
          simple_test_class.new.each_embedded_transition(options) do |item|
            results << item
          end
          results[2..3].to_a.collect{|x| x.to_a }.should == [['first', 'first_link'], ['second', 'second_link']]
        end



        it 'raises an error if options are passed that are not a hash' do
          expect { simple_test_class.new.each_link_transition(:options).to_a }.to raise_error(ArgumentError,
            /options must be nil or a hash. Received ':options'./)
        end

        shared_examples_for 'a filtered list of embedded transitions' do
          context 'with :include option' do
            before do
              @options = {include: :leviathan}
            end
            
            it 'returns only the specified transition descriptors' do
              @comparison_links.each { |link| embedded_transitions[link].should be_nil }
            end

            it 'excludes all unspecified transition descriptors' do
              @comparison_links.each { |link| embedded_transitions[link].should be_nil }
            end
          end

          context 'with :exclude option' do
            before do
              @options = {exclude: 'leviathan'}
            end
            
            it 'excludes all the transition descriptors that were specified' do
              embedded_transitions['leviathan-link'].should be_nil
            end

            it 'returns all other unspecified the transition descriptors' do
              @comparison_links.each { |link| embedded_transitions[link].should_not be_nil }
            end
          end
        end

        context 'without a state' do
          before do
            @comparison_links = %w(repair-history)
          end

          it 'returns all link transitions' do
            %w(leviathan-link repair-history).each { |id| embedded_transitions[id].should_not be_nil }
          end

          it_behaves_like 'a filtered list of embedded transitions'
        end
        
        shared_examples_for 'an embedded transition enumerator' do
          context 'without :conditions option' do
            before do
              @conditions = nil
            end

            it 'only includes transitions available for the state that do not have conditions' do
              embedded_transitions['leviathan-link'].should_not be_nil
            end

            it 'excludes transitions available for the state that have conditions' do
              embedded_transitions['repair-history'].should be_nil
            end
          end

          context 'with :conditions option' do
            it 'only includes transition descriptors available for the state with satisfied conditions' do
              %w(leviathan-link repair-history).each { |id| embedded_transitions[id].should_not be_nil }
            end

            it 'excludes all transition descriptors available for the state with unsatisfied conditions' do
              @conditions = :cannot_repair
              embedded_transitions['repair-history'].should be_nil
            end
          end
        end

        context 'with a :state option' do
          before do
            @state = 'activated'
            @comparison_links = %w(repair-history)
            @conditions = :can_repair
          end

          it_behaves_like 'a filtered list of embedded transitions'

          it_behaves_like 'an embedded transition enumerator'
        end

        context 'with a valid state_method' do
          before do
            @state_method = 'my_state_method'
            @attributes = {'my_state_method' => 'activated'}
            @comparison_links = %w(repair-history)
            @conditions = :can_repair
          end

          it_behaves_like 'a filtered list of embedded transitions'

          it_behaves_like 'an embedded transition enumerator'

          it 'raises an error if the state is not a string or a symbol' do
            attributes = {'my_state_method' => mock('invalid_state')}
            expect { simple_test_class.new(attributes).each_link_transition.to_a }.to raise_error(
                Crichton::RepresentorError,
                /^The state method 'my_state_method' must return a string or a symbol.*/
            )
          end
        end
        
        context 'with no state_method' do
          it 'raises an error' do
            @include_state = true
            expect { simple_test_class.new.each_link_transition.to_a }.to raise_error(
              Crichton::RepresentorError,
              /^No state method has been defined in the class ''.*/
            )
          end
        end
      end
      
      describe '#each_link_transition' do
        let(:link_transitions) do
          simple_test_class.new(@attributes).each_link_transition(options).inject({}) do |h, descriptor|
            h.tap { |hash| hash[descriptor.id] = descriptor }
          end
        end
      
        before do
          @resource_name = 'drd'
        end
      
        it 'returns an enumerator' do
          simple_test_class.new.each_link_transition.should be_a(Enumerable)
        end
      
        it 'yields decorated transition descriptors' do
          simple_test_class.new.each_link_transition.all? do |item|
            item.instance_of?(Crichton::Descriptor::TransitionDecorator)
          end
        end

        it 'raises an error if options are passed that are not a hash' do
          expect { simple_test_class.new.each_link_transition('options').to_a }.to raise_error(ArgumentError,
            /options must be nil or a hash. Received '"options"'./)
        end
        
        shared_examples_for 'a filtered list of link transitions' do
          context 'with :only option' do
            before do
              @options = {only: :self}
            end
            
            it 'returns only the specified transition descriptors' do
              link_transitions['show'].should_not be_nil
            end

            it 'excludes all other transition descriptors' do
              @comparison_links.each { |link| link_transitions[link].should be_nil }
            end
          end

          context 'with :except option' do
            before do
              @options = {except: 'self'}
            end
            
            it 'excludes the specified transition descriptors' do
              link_transitions['show'].should be_nil
            end

            it 'returns all other transition descriptors' do
              @comparison_links.each { |link| link_transitions[link].should_not be_nil }
            end
          end
        end
      
        context 'without a state' do
          before do
            @comparison_links = %w(activate deactivate update delete)
          end
        
          it 'returns all link transitions' do
            %w(show activate deactivate update delete).each { |id| link_transitions[id].should_not be_nil }
          end
        
          it_behaves_like 'a filtered list of link transitions'
        end

        shared_examples_for 'a link transition enumerator' do

          context 'without :conditions option' do
            before do
              @conditions = nil
            end

            it 'only includes transitions available for the state that do not have conditions' do
              link_transitions['show'].should_not be_nil
            end

            it 'excludes transitions available for the state that have conditions' do
              %w(deactivate update delete).each { |id| link_transitions[id].should be_nil }
            end
          end

          context 'with :conditions option' do
            it 'only includes transitions available for the state' do
              %w(activate update delete).each { |id| link_transitions[id].should be_nil }
            end

            it 'excludes transitions available for the state with unsatisfied conditions' do
              %w(activate update delete).each { |id| link_transitions[id].should be_nil }
            end
          end
        end
      
        context 'with a :state option' do
          before do
            @state = 'activated'
            @comparison_links = %w(deactivate)
            @conditions = :can_deactivate
          end

          it_behaves_like 'a filtered list of link transitions'

          it_behaves_like 'a link transition enumerator'
        end

        context 'with a valid state_method' do
          before do
            @state_method = 'my_state_method'
            @attributes = {'my_state_method' => 'activated'}
            @comparison_links = %w(deactivate)
            @conditions = :can_deactivate
          end

          it_behaves_like 'a filtered list of link transitions'

          it_behaves_like 'a link transition enumerator'

          it 'raises an error if the state is not a string or a symbol' do
            attributes = {'my_state_method' => mock('invalid_state')}
            expect { simple_test_class.new(attributes).each_link_transition.to_a }.to raise_error(
              Crichton::RepresentorError,
              /The state method 'my_state_method' must return a string or a symbol.*/
            )
          end
        end
      end
      
      describe '#metadata_links' do
        it 'returns the metadata links associated with the represented resource' do
          @resource_name = 'drds'
          simple_test_class.new.metadata_links.map(&:rel).should == %w(profile type help)
        end
      end
      
      describe '#method_missing' do
        it 'continues to raise an error when an unknown method is called' do
          expect { simple_test_class.new.bogus }.to raise_error(NoMethodError, /undefined method `bogus'.*/)
        end
      end
    end

    context "BaseSemanticBuilder" do
      describe '#logger' do
        let(:builder) { Crichton::Representor::XHTMLSerializer::BaseSemanticBuilder.new('xhtml', {}, 'markup') }
        it 'allows access to the Crichton logger' do
          logger = double('logger')
          Crichton.should_receive(:logger).once.and_return(logger)
          builder.logger.should == logger
        end

        it 'memoizes the logger' do
          doubled_logger = double("logger")
          Crichton.stub(:logger).and_return(doubled_logger)
          memoized_logger = builder.logger
          builder.logger.object_id.should == memoized_logger.object_id
        end
      end
    end
  end
end
