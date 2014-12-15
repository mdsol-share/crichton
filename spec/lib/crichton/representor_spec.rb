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
      expect(simple_test_class.new).to be_a(Representor::Serialization::MediaType)
    end
    
    context 'with associated class-level descriptors' do
      before do
        @resource_name = 'drds'
        Crichton.initialize_registry(drds_descriptor)
      end
      
      describe '.data_semantic_descriptors' do
        it 'returns the filtered list of semantic data descriptors' do
          expect(simple_test_class.data_semantic_descriptors.map(&:name)).to eq(%w(total_count))
        end
      end

      describe '.embedded_semantic_descriptors' do
        it 'returns the filtered list of semantic embedded descriptors' do
          expect(simple_test_class.embedded_semantic_descriptors.map(&:name)).to eq(%w(items))
        end
      end

      describe '.link_transition_descriptors' do
        it 'returns the filtered list of link transition descriptors mapped by name' do
          expect(simple_test_class.link_transition_descriptors.first.name).to eq('list')
        end
      end

      describe '.embedded_transition_descriptors' do
        it 'returns the filtered list of embedded transition descriptors' do
          @resource_name = 'drd'
          expect(simple_test_class.embedded_transition_descriptors.first.name).to eq('leviathan')
        end
      end
    end
    
    describe '.represents' do
      it 'sets the resource name of the represented resource' do
        simple_test_class.represents :some_resource
        expect(simple_test_class.resource_name).to eq('some_resource')
      end
    end
    
    describe '.resource_descriptor' do
      it 'raises an error if no resource name has been defined for the class' do
        allow(Crichton).to receive(:descriptor_registry).and_return({})
        allow(Crichton).to receive(:config_directory).and_return(resource_descriptor_fixtures)
        expect { simple_test_class.resource_descriptor }.to raise_error(Crichton::RepresentorError,
          /^No resource name has been defined.*/)
      end
      
      it 'returns the resource descriptor registered with the resource name' do
        resource_descriptor = double('resource_descriptor')
        @resource_name = 'resource'
        allow(Crichton).to receive(:descriptor_registry).and_return(@resource_name => resource_descriptor)
        
        expect(simple_test_class.resource_descriptor).to eq(resource_descriptor)
      end
    end
    
    describe '.resource_name' do
      it 'raises an error if no resource name has been defined for the class' do
        expect { simple_test_class.resource_name }.to raise_error(Crichton::RepresentorError,
          /^No resource name has been defined.*/)
      end
      
      it 'returns the resource name set on the base class' do
        @resource_name = :resource
        expect(simple_test_class.resource_name).to eq('resource')
      end
    end

    context 'with_registered resource descriptor' do
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
          expect(simple_test_class.new.each_data_semantic).to be_a(Enumerable)
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
          @attributes.each { |k, v| expect(data_semantics[k].value).to eq(v) }
        end
        
        it 'excludes semantic descriptors that do not exist on the representor instance' do
          expect(data_semantics['status']).to be_nil
        end
        
        context 'with :only option' do
          before do
            @options = {only: :uuid}
          end
          
          it 'returns the specified semantic descriptors' do
            expect(data_semantics['uuid']).not_to be_nil
          end

          it 'excludes all other semantic descriptors' do
            expect(data_semantics['name']).to be_nil
          end
        end

        context 'with :except option' do
          before do
            @options = {except: :uuid}
          end
          
          it 'excludes all specified semantic descriptors' do
            expect(data_semantics['uuid']).to be_nil
          end

          it 'returns all other semantic descriptors' do
            expect(data_semantics['name']).not_to be_nil
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
          @item = double('item')
          @attributes = {'items' => [@item]}
        end

        it 'returns an enumerator' do
          expect(simple_test_class.new.each_data_semantic).to be_a(Enumerable)
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
          expect(embedded_semantics['items'].value).to eq([@item])
        end

        context 'with :include option' do
          it 'returns only the specified semantic descriptors' do
            @options = {include: :items}
            expect(embedded_semantics['items']).not_to be_nil
          end
        end

        context 'with :except option' do
          it 'returns all the semantic descriptors that were not excluded' do
            @options = {exclude: :items}
            expect(embedded_semantics['items']).to be_nil
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

      describe '#each_transition' do
        let(:transitions) do
          simple_test_class.new(@attributes).each_transition(options).inject({}) do |h, descriptor|
            h.tap { |hash| hash[descriptor.id] = descriptor }
          end
        end

        before do
          @resource_name = 'drd'
        end

        it 'returns an enumerator' do
          expect(simple_test_class.new.each_transition).to be_a(Enumerable)
        end

        it 'yields decorated transition descriptors' do
          simple_test_class.new.each_transition.all? do |item|
            item.instance_of?(Crichton::Descriptor::TransitionDecorator)
          end
        end

        it 'yields additional links' do
          @top_level = true
          @additional_links = {'first' => 'first_link', 'second' => 'second_link'}
          results = []
          simple_test_class.new.each_transition(options) do |item|
            results << item.to_a if item.is_a?(Crichton::Descriptor::AdditionalTransition)
          end
          expect(results).to eq([['first', 'first_link'], ['second', 'second_link']])
        end

        it 'raises an error if options are passed that are not a hash' do
          expect { simple_test_class.new.each_transition(:options).to_a }.to raise_error(
            ArgumentError,
            /options must be nil or a hash. Received ':options'./
          )
        end

        shared_examples_for 'a filtered list of transitions' do
          context 'with :only option' do
            before do
              @options = {only: [:show, :leviathan]}
            end

            it 'returns only the specified transition descriptors' do
              [transitions['leviathan-link'], transitions['show']].all? do |item|
                expect(item).not_to be_nil
              end
            end

            it 'excludes all unspecified transition descriptors' do
              @comparison_links.each { |link| expect(transitions[link]).to be_nil }
            end
          end

          context 'with :exclude option' do
            before do
              @options = {exclude: [:show, :leviathan]}
            end

            it 'excludes all the transition descriptors that were specified' do
              [transitions['leviathan-link'], transitions['show']].all? do |item|
                expect(item).to be_nil
              end
            end

            it 'returns all other unspecified the transition descriptors' do
              @comparison_links.each { |link| expect(transitions[link]).not_to be_nil }
            end
          end

          context 'with :except option' do
            before do
              @options = {except: [:show, :leviathan]}
            end

            it 'excludes all the transition descriptors that were specified' do
              [transitions['leviathan-link'], transitions['show']].all? do |item|
                expect(item).to be_nil
              end
            end

            it 'returns all other unspecified the transition descriptors' do
              @comparison_links.each { |link| expect(transitions[link]).not_to be_nil }
            end
          end
        end

        context 'without a state' do
          before do
            descriptor = drds_descriptor.tap do |document|
              state = document['resources']['drd']['states']['activate']
              document['resources']['drd']['states'].clear.merge!({'default' => state })
            end
            Crichton.initialize_registry(descriptor)
            @comparison_links = %w(repair-history activate deactivate update delete)
          end

          it 'returns all link transitions' do
            %w(leviathan-link repair-history).each { |id| expect(transitions[id]).not_to be_nil }
          end

          it_behaves_like 'a filtered list of transitions'
        end

        shared_examples_for 'a transition enumerator' do
          context 'without :conditions option' do
            before do
              @conditions = nil
            end

            it 'only includes transitions available for the state that do not have conditions' do
              [transitions['leviathan-link'], transitions['show']].all? do |item|
                expect(item).not_to be_nil
              end
            end

            it 'excludes transitions available for the state that have conditions' do
              [transitions['repair-history'], transitions['delete']].all? do |item|
                expect(item).to be_nil
              end
            end
          end

          context 'with :conditions option' do
            it 'only includes transition descriptors available for the state with satisfied conditions' do
              %w(leviathan-link repair-history).each { |id| expect(transitions[id]).not_to be_nil }
            end

            it 'excludes all transition descriptors available for the state with unsatisfied conditions' do
              @conditions = :cannot_repair
              expect(transitions['repair-history']).to be_nil
            end
          end
        end

        context 'with a :state option' do
          before do
            @state = 'activated'
            @comparison_links = %w(repair-history)
            @conditions = :can_repair
          end

          it_behaves_like 'a filtered list of transitions'

          it_behaves_like 'a transition enumerator'
        end

        context 'with a valid state_method' do
          before do
            @state_method = 'my_state_method'
            @attributes = {'my_state_method' => 'activated'}
            @comparison_links = %w(repair-history)
            @conditions = :can_repair
          end

          it_behaves_like 'a filtered list of transitions'

          it_behaves_like 'a transition enumerator'

          it 'raises an error if the state is not a string or a symbol' do
            attributes = {'my_state_method' => double('invalid_state')}
            expect { simple_test_class.new(attributes).each_transition.to_a }.to raise_error(
              Crichton::RepresentorError,
              /^The state method 'my_state_method' must return a string or a symbol.*/
            )
          end
        end

        context 'with no state_method' do
          it 'raises an error' do
            @include_state = true
            expect { simple_test_class.new.each_transition.to_a }.to raise_error(
              Crichton::MissingStateError,
              /^No state 'default' defined for resource 'drd' in API descriptor document with ID: DRDs/
            )
          end
        end

        context 'with no explicit or default state method' do
          it 'raises an error' do
            @include_state = true
            @state_method = nil
            klass = simple_test_class
            klass.send(:undef_method, :state)
            expect { klass.new.each_transition.to_a }.to raise_error(
              Crichton::RepresentorError,
              /^No state method has been defined/
            )
          end
        end

      end

      describe '#metadata_links' do
        it 'returns the metadata links associated with the represented resource' do
          @resource_name = 'drds'
          expect(simple_test_class.new.metadata_links.map(&:rel)).to eq(%w(profile type help))
        end
      end

      describe '#self_transition' do
        let(:subject) { simple_test_class.new.self_transition(options) }

        before do
          @resource_name = 'drds'
          @state = 'collection'
          @conditions = :can_do_anything
        end

        it 'returns decorated transition descriptor' do
          expect(subject).to be_a(Crichton::Descriptor::TransitionDecorator)
        end

        it 'returns the transition with the name self' do
          expect(subject.name).to eq('self')
        end

        it 'returns the transition with id of the specified self transition' do
          expect(subject.id).to eq('list')
        end
      end

      describe '#response_headers' do
        let(:attributes) { { @state_method => @state } }
        let(:subject) { simple_test_class.new(attributes) }
        before do
          @state_method = 'my_state_method'
          @state = 'collection'
          @resource_name = 'drds'
        end

        it 'returns empty hash if not response headers are specified' do
          @resource_name = 'drd'
          @state = 'activated'
          expect(subject.response_headers).to be_empty
        end

        it 'returns non empty response headers hash if specified' do
          expect(subject.response_headers).to have(1).item
        end

        it 'returns response headers hash if specified' do
          expect(subject.response_headers).to eq({ 'Cache-Control' => 'no-cache' })
        end

        it 'returns empty hash if self transition is nil' do
          subject.stub(:self_transition).and_return(nil)
          expect(subject.response_headers).to be_empty
        end

        it 'returns empty hash if self transition is not TransitionDecorator' do
          subject.stub(:self_transition).and_return(an_instance_of(Array))
          expect(subject.response_headers).to be_empty
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
        let(:builder) { Crichton::Representor::XHTMLSerializer::BaseSemanticBuilder.new('xhtml', {}, 'markup', nil) }
        it 'allows access to the Crichton logger' do
          logger = double('logger')
          expect(Crichton).to receive(:logger).once.and_return(logger)
          expect(builder.logger).to eq(logger)
        end

        it 'memoizes the logger' do
          doubled_logger = double("logger")
          allow(Crichton).to receive(:logger).and_return(doubled_logger)
          memoized_logger = builder.logger
          expect(builder.logger.object_id).to eq(memoized_logger.object_id)
        end
      end
    end
  end
end
