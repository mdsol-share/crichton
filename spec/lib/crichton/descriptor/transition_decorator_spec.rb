require 'spec_helper'
require 'crichton/descriptor/transition_decorator'

module Crichton
  module Descriptor
    describe TransitionDecorator do
      let(:descriptor_document) { normalized_drds_descriptor }
      let(:resource_descriptor) { Resource.new(descriptor_document) }
      let(:descriptor) do
        register_drds_descriptor
        Crichton.descriptor_registry[@descriptor || 'drds'].transitions[@transition || 'list']
      end
      let(:options) do
        {}.tap do |options|
          options[:state] = (@state || 'collection') unless @skip_state_option
          options[:conditions] = @conditions
          options[:protocol] = @protocol
          options[:override_links] = @override_links if @override_links
          # Yes, I want the .nil? as this could be true or false
          options[:top_level] = @top_level unless @top_level.nil?
        end
      end
      let(:target) do
        if @skip_state_option
          state = @state
          target_class = Class.new do
            include Crichton::Representor::State
            
            def self.name; 'target' end

            define_method(:state) { state }
          end
          target_class.new
        else
          double('target')
        end
      end
      let(:decorator) { TransitionDecorator.new(target, descriptor, options) }

      describe '#name' do
        it 'returns the name of the state transition' do
          expect(decorator.name).to eq('self')
        end

        it 'returns the id of the descriptor if name is not specified' do
          @transition = 'search'
          expect(decorator.name).to eq('search')
        end
      end

      describe '#available?' do
        shared_examples_for 'a state transition without conditions' do
          it 'always returns true for transitions without conditions' do
            @skip_state_option = false
            expect(decorator).to be_available
          end
          
          it 'returns false for a transition that is not listed for the state' do
            @descriptor = 'drd'
            @state = 'activated'
            @transition = 'activate'

            expect(decorator).to_not be_available
          end
        end
        
        shared_examples_for 'a state transition' do
          context 'with a :conditions option' do
            it_behaves_like 'a state transition without conditions' 
            
            it 'returns true if a single state condition is satisfied' do
              @descriptor = 'drd'
              @state = 'activated'
              @transition = 'deactivate'
              @conditions = :can_deactivate

              expect(decorator).to be_available
            end

            it 'returns true if multiple state conditions are satisfied' do
              @descriptor = 'drd'
              @state = 'deactivated'
              @transition = 'activate'
              @conditions = [:can_activate, 'can_do_anything']
              
              expect(decorator).to be_available
            end

            it 'returns false if at least one state condition is not satisfied' do
              @descriptor = 'drd'
              @state = 'deactivated'
              @transition = 'activate'
              @conditions = 'can_cook'
              
              expect(decorator).to_not be_available
            end
          end

          context 'without a :conditions option' do
            it_behaves_like 'a state transition without conditions'

            it 'always returns false if a state condition is not satisfied' do
              @descriptor = 'drd'
              @state = 'activated'
              @transition = 'deactivate'

              expect(decorator).to_not be_available
            end
          end
        end
        
        context 'with target that does not implement a #state method' do
          context 'without :state specified in the options' do
            it 'always returns true' do
              expect(decorator).to be_available
            end
          end
          
          context 'with a :state option' do
            it_behaves_like 'a state transition'
          end
        end

        context 'with target that implements the State module' do
          before do
            @skip_state_option = true
          end

          it_behaves_like 'a state transition'

          context 'with a nil state' do
            it 'it raises an error' do
              expect { decorator.available? }.to raise_error(Crichton::RepresentorError,
                /^The state was nil in the class 'target'.*/)
            end
          end
        end

        context 'with an illegal state' do
          it 'logs a warning' do
            @descriptor = 'drd'
            @state = 'junk'
            @transition = 'deactivate'
            expect { decorator.available? }.to raise_error(Crichton::MissingStateError,
              /^No state 'junk' defined for resource 'drd' in API descriptor document with ID: DRDs/)
          end
        end
      end

      describe '#interface_method' do
        it 'returns the uniform interface method associated with the transition' do
          @descriptor = 'drd'
          @transition = 'delete'

          expect(decorator.interface_method).to eq('DELETE')
        end

        it 'returns nil if there is not protocol descriptor' do
          allow(decorator).to receive(:protocol_descriptor).and_return(nil)
          expect(decorator.interface_method).to be_nil
        end
      end

      describe '#protocol' do
        context 'without :protocol option' do
          it 'returns the default protocol for the parent resource descriptor' do
            expect(decorator.protocol).to eq(resource_descriptor.default_protocol)
          end
        end

        context 'with :protocol option' do
          it 'raises an error if the protocol is not defined for the parent resource descriptor' do
            @protocol = 'bogus'
            expect { decorator.protocol }.to raise_error(/^Unknown protocol bogus defined by options.*/)
          end
        end
      end
      
      describe '#protocol_descriptor' do
        it 'returns the protocol descriptor that details the implementation of the transition' do
          expect(decorator.protocol_descriptor).to be_a(Http)
        end
        
        it 'returns nil if no protocol descriptor implements the transition for the transition protocol' do
          allow(decorator).to receive(:id).and_return('non-existent')
          expect(decorator.protocol_descriptor).to be_nil
        end
      end
      
      describe '#templated?' do
        before do
          @state = 'navigation'
        end

        it 'returns true if the transition has semantic descriptors' do
          @transition = 'search'
          debugger
          expect(decorator).to be_templated
        end

        it 'returns false if the transition has no semantic descriptors' do
          expect(decorator).to_not be_templated
        end
      end

      let(:deployment_base_uri) { 'http://deployment.example.org' }

      def stub_config
        config = Crichton::Configuration.new({'deployment_base_uri' => deployment_base_uri})
        allow(Crichton).to receive(:config).and_return(config)
      end
      
      describe '#templated_url' do
        before do
          stub_config
        end
        
        context 'without query parameter semantic descriptors' do
          it 'returns the url' do
            expect(decorator.templated_url).to eq(decorator.url)
          end
        end

        context 'with query parameter semantic descriptors' do
          it 'returns the url with templated query parameters' do
            Crichton.clear_config
            @transition = 'search'
            expect(decorator.templated_url).to match(/{?search_term,search_name}/)
          end
        end
      end
      
      describe '#url' do
        before do
          stub_config
        end
        
        shared_examples_for 'a memoized url' do
          it 'memoizes the url' do
            url_object_id = decorator.url.object_id
            expect(decorator.url.object_id).to eq(url_object_id)
          end
        end
        
        context 'with protocol descriptor defined for transition' do
          context 'with parameterized uri' do
            before do
              @descriptor = 'drd'
              @transition = 'activate'
              allow(target).to receive(:uuid).and_return('some_uuid')
            end

            it 'returns the uri populated from the target attributes' do
              expect(decorator.url).to match(/#{deployment_base_uri}\/drds\/some_uuid\/activate/)
            end
            
            it_behaves_like 'a memoized url'
          end

          context 'without parameterized uri' do
            it 'returns the uri as a url' do
              expect(decorator.url).to match(/#{deployment_base_uri}\/drds/)
            end

            it_behaves_like 'a memoized url'
          end
          
          context 'with embedded transition' do
            before do
              @descriptor = 'drd'
              @transition = 'leviathan-link'
              @url = double('url')
              allow(target).to receive('leviathan_url').and_return(@url)
            end
            
            it 'returns the url associated with the source method' do
              expect(decorator.url).to eq(@url)
            end
            
            it_behaves_like 'a memoized url'
          end
        end
        
        context 'without protocol descriptor defined' do
          it 'returns nil' do
            allow(decorator).to receive(:protocol_descriptor).and_return(nil)
            expect(decorator.url).to be_nil
          end
        end

        context 'with override_links in the options hash' do
          before do
            @overridden_url = "OVERRIDDEN URL"
          end

          it 'uses the override link instead of the regular URL' do
            @override_links = {'self' => @overridden_url}
            @top_level = true
            expect(decorator.url).to be(@overridden_url)
          end

          it 'uses regular URL if the name does not match' do
            @override_links = {'wrong_name' => @overridden_url}
            @top_level = true
            expect(decorator.url).to_not be(@overridden_url)
          end

          it 'uses the regular URL if it is not top_level' do
            @override_links = {'self' => @overridden_url}
            @top_level = false
            expect(decorator.url).to_not be(@overridden_url)
          end
        end
      end
    end
  end
end
