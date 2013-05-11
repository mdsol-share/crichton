require 'spec_helper'

module Crichton
  module Descriptor
    describe TransitionDecorator do
      let(:descriptor_document) { drds_descriptor }
      let(:resource_descriptor) { Resource.new(descriptor_document) }
      let(:descriptor) { resource_descriptor.semantics[@descriptor || 'drds'].transitions[@transition || 'list'] }
      let(:options) do
        {}.tap do |options|
          options[:state] = @state unless @skip_state
          options[:conditions] = @conditions
          options[:protocol] = @protocol
        end
      end
      let(:target) { mock('target') }
      let(:decorator) { TransitionDecorator.new(target, descriptor, options) }

      describe '#available?' do
        shared_examples_for 'a state transition without conditions' do
          it 'always returns true for transitions without conditions' do
            @state = 'collection'
            decorator.should be_available
          end
          
          it 'returns false for a transition that is not listed for the state' do
            @descriptor = 'drd'
            @state = 'activated'
            @transition = 'activate'

            decorator.should_not be_available
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
              
              decorator.should be_available
            end

            it 'returns true if multiple state conditions are satisfied' do
              @descriptor = 'drd'
              @state = 'deactivated'
              @transition = 'activate'
              @conditions = [:can_activate, 'can_do_anything']
              
              decorator.should be_available
            end

            it 'returns false if at least one state condition is not satisfied' do
              @descriptor = 'drd'
              @state = 'deactivated'
              @transition = 'activate'
              @conditions = 'can_cook'
              
              decorator.should_not be_available
            end
          end

          context 'without a :conditions option' do
            it_behaves_like 'a state transition without conditions'

            it 'always returns false if a state condition is not satisfied' do
              @descriptor = 'drd'
              @state = 'activated'
              @transition = 'deactivate'
              
              decorator.should_not be_available
            end
          end
        end
        
        context 'with target that does not implement a #state method' do
          context 'without :state specified in the options' do
            it 'always returns true' do
              decorator.should be_available
            end
          end
          
          context 'with a :state option' do
            it_behaves_like 'a state transition'
          end
        end
        
        context 'with target that implements the State module' do
          before do
            @skip_state = true
          end
          
          let(:target) do
            state = @state
            target_class = Class.new do 
              include Crichton::Representor::State   
              
              state_method state

              # Note: the following code is for the test only. Normally, #state_method points to existing method.
              define_method(state) { state } if state 
            end
            target_class.new
          end
          
          it_behaves_like 'a state transition'

          context 'with a nil state' do
            it 'it raises an error' do
              expect { decorator.available? }.to raise_error(Crichton::Representor::Error, 
                /^No state method has been defined in the class.*/)
            end
          end
        end
      end
      
      describe '#protocol' do
        context 'without :protocol option' do
          it 'returns the default protocol for the parent resource descriptor' do
            decorator.protocol.should == resource_descriptor.default_protocol
          end
          
          it 'raises an error if there is no default protocol defined for the resource descriptor' do
            descriptor_document['protocols'] = {}
            expect { decorator.protocol }.to raise_error(/No protocols defined for the resource descriptor DRDs.*/)
          end
        end

        context 'with :protocol option' do
          it 'returns the specified protocol' do
            @protocol = 'option_protocol'
            resource_descriptor.stub(:protocol_exists?).with(@protocol).and_return(true)
            decorator.protocol.should == @protocol
          end
          
          it 'raises an error if the protocol is not defined for the parent resource descriptor' do
            @protocol = 'bogus'
            expect { decorator.protocol }.to raise_error(/^Unknown protocol bogus defined by options.*/)
          end
        end
      end

      describe '#protocol_descriptor' do
        it 'returns the protocol descriptor that details the implementation of the transition' do
          decorator.protocol_descriptor.should be_a(Http)
        end
        
        it 'returns nil if no protocol descriptor implements the transition for the transition protocol' do
          decorator.stub(:id).and_return('non-existent')
          decorator.protocol_descriptor.should be_nil
        end
      end
      
      describe '#url' do
        it 'returns the fully qualified url for the transition' do
          pending 'TODO'
        end
      end
    end
  end
end
