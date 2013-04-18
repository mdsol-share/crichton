module Support
  module Helpers
    def drds_descriptor
      YAML.load_file(drds_filename)
    end

    def drds_filename
      fixture_path('resource_descriptors', 'drds_descriptor_v1.yml')
    end

    def leviathans_descriptor
      YAML.load_file(leviathans_filename)
    end

    def leviathans_filename
      fixture_path('resource_descriptors', 'leviathans_descriptor_v1.yaml')
    end

    def resource_descriptor_fixtures
      fixture_path('resource_descriptors')
    end

    shared_examples_for 'a nested descriptor' do
      it 'responds to descriptors' do
        descriptor.should respond_to(:semantics)
      end

      it 'responds to semantics' do
        descriptor.should respond_to(:semantics)
      end

      it 'responds to transitions' do
        descriptor.should respond_to(:transitions)
      end
    end
    
    shared_examples_for 'it serializes to ALPS' do
      context 'when hash' do
        describe '#to_alps_hash' do
          context 'without options' do
            it 'returns a hash in an ALPS profile structure' do
              descriptor.to_alps_hash.should == alps_profile
            end
          end
  
          context 'with top_level option false' do
            it 'returns a hash in an ALPS descriptor structure' do
              descriptor.to_alps_hash(top_level: false)['alps'].should be_nil
            end
          end
        end
      end
      
      context 'when JSON' do
        describe '#to_json' do
          context 'without options' do
            it 'returns a JSON ALPS profile structure' do
              JSON.parse(descriptor.to_json).should == alps_profile
            end
          end
  
          context 'with pretty option true' do
            it 'returns a json alps profile pretty-formatted' do
              MultiJson.should_receive(:dump).with(descriptor.to_alps_hash, pretty: true)
              descriptor.to_json(pretty: true)
            end
          end
        end
      end
      
      context 'when XML' do
        it 'returns an XML ALPS profile structure' do
          descriptor.to_xml.should be_equivalent_to(alps_xml)
        end
      end
    end
    
    private
    def fixture_path(*args)
      File.join(SPEC_DIR, 'fixtures', args)
    end
  end
end
