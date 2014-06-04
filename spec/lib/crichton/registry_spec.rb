require 'spec_helper'
require 'crichton'

module Crichton
  describe Registry do
    describe '.initialize' do
      context 'with a directory of resource descriptors specified' do
        before do
          allow(Crichton).to receive(:descriptor_location).and_return(resource_descriptor_fixtures)
        end

        it 'loads resource descriptors from a resource descriptor directory if configured' do
          expect(Registry.new.descriptor_registry.size).to eq(3)
        end
      end

      context 'without a directory of resource descriptors specified' do
        before do
          allow(Crichton).to receive(:descriptor_filenames).and_return([drds_non_existent_filename])
        end

        it 'raises an error' do
          expect { Registry.new.descriptor_registry }.to raise_error("Filename #{drds_non_existent_filename} is not valid.")
        end
      end
    end

    describe '.register_single' do
      it 'accepts a descriptor document' do
        registry = Registry.new(automatic_load: false)
        registry.register_single(drds_descriptor)
        expect(registry.raw_descriptor_registry.keys).to eq(%w(drds drd))
      end

      it 'accepts a filename' do
        registry = Registry.new(automatic_load: false)
        registry.register_single(drds_filename)
        expect(registry.raw_descriptor_registry.keys).to eq(%w(drds drd))
      end

      it 'loads all descriptors from a resource descriptor' do
        registry = Registry.new(automatic_load: false)
        registry.register_single(drds_descriptor)
        expect(registry.raw_descriptor_registry.keys.size).to eq(2)
      end
    end

    describe '.register_multiple' do
      it 'accepts descriptor documents' do
        registry = Registry.new(automatic_load: false)
        registry.register_multiple([drds_descriptor, leviathans_descriptor])
        expect(registry.raw_descriptor_registry.keys).to eq(%w(drds drd leviathan))
      end

      it 'accepts filenames' do
        registry = Registry.new(automatic_load: false)
        registry.register_multiple([drds_filename, leviathans_filename])
        expect(registry.raw_descriptor_registry.keys).to eq(%w(drds drd leviathan))
      end

      it 'accepts a document and a filename' do
        registry = Registry.new(automatic_load: false)
        registry.register_multiple([drds_descriptor, leviathans_filename])
        expect(registry.raw_descriptor_registry.keys).to eq(%w(drds drd leviathan))
      end
    end

    describe '#resources_registry' do
      let(:registry) { Registry.new(automatic_load: false) }

      it 'returns an empty hash hash if no resource descriptors are registered' do
        expect(registry.resources_registry).to be_empty
      end

      it 'returns a hash of registered resource descriptors keyed by document id' do
        resources_registry = registry.register_single(drds_descriptor)

        resources_registry.each do |key, resource_dereferencer|
          expect(registry.resources_registry[key]).to eq(resource_dereferencer)
        end
      end
    end

    describe '.raw_descriptor_registry' do
      let(:registry) { Registry.new(automatic_load: false) }

      it 'returns an empty hash hash if no resource descriptors are registered' do
        expect(registry.raw_descriptor_registry).to be_empty
      end

      it 'returns a hash of registered descriptor instances keyed by descriptor id' do
        resources_registry = registry.register_single(drds_descriptor)
        dealiased_hash = resources_registry['DRDs'].dealiased_document
        resource_descriptor = Crichton::Descriptor::Resource.new(dealiased_hash)

        resource_descriptor.resources.each do |descriptor|
          expect(registry.raw_descriptor_registry[descriptor.id].name).to eq(descriptor.name)
        end
      end
    end

    describe '.raw_profile_registry' do
      let(:registry) { Registry.new(automatic_load: false) }

      it 'returns an empty hash hash if no resource descriptors are registered' do
        expect(registry.raw_profile_registry).to be_empty
      end

      it 'returns a hash of registered descriptor instances keyed by profile id' do
        resources_registry = registry.register_single(drds_descriptor)
        dealiased_hash = resources_registry['DRDs'].dealiased_document
        resource_descriptor = Crichton::Descriptor::Resource.new(dealiased_hash)

        expect(registry.raw_profile_registry[resource_descriptor.id].name).to eq(resource_descriptor.name)
      end
    end

    describe '.register_single' do
      let(:registry) { Registry.new(automatic_load: false) }

      it 'returns a hash of registered resource descriptors' do
        expect(registry.register_single(drds_descriptor)).to be_a(Hash)
      end

      it 'returns a hash of registered resource dereferencer instances' do
        registry.register_single(drds_descriptor).values.each do |v|
          expect(v).to be_a(Crichton::Descriptor::ResourceDereferencer)
        end
      end

      it 'raises an error when the resource descriptor is not a string or hash' do
        resource_descriptor = double('invalid_descriptor')
        expect { registry.register_single(resource_descriptor) }.to raise_error(ArgumentError)
      end

      shared_examples_for 'a resource descriptor registration' do
        it 'registers a the child detail descriptors by id in the raw registry' do
          resources_registry = registry.register_single(@descriptor)

          resources_registry.each do |id, resource|
            expect(registry.resources_registry[id]).to eq(resource)
          end
        end
      end

      context 'with a filename as an argument' do
        before do
          @descriptor = drds_filename
        end

        it_behaves_like 'a resource descriptor registration'

        it 'raises an error if the filename is invalid' do
          expect { registry.register_single('invalid_filename') }.to raise_error(ArgumentError,
            'Filename invalid_filename is not valid.')
        end
      end

      context 'with a hash resource descriptor as an argument' do
        before do
          @descriptor = drds_descriptor
        end

        it_behaves_like 'a resource descriptor registration'
      end
    end

    describe '.registrations?' do
      let(:registry) { Registry.new(automatic_load: false) }

      it 'returns false if no resource descriptors are registered' do
        expect(registry.registrations?).to be_false
      end

      it 'returns true if resource descriptors are registered' do
        stub_alps_requests
        registry.register_single(drds_descriptor)
        expect(registry.registrations?).to be_true
      end
    end

    describe '#external_profile_dereference' do
      let(:registry) { Registry.new(automatic_load: false) }
      let(:uri) { @uri }

      it 'returns empty hash when uri can not be resolved' do
        @uri = 'http://example.org/Something'
        expect(registry.external_profile_dereference(uri)).to be_empty
      end

      it 'returns empty hash when deserialized hash does not have descriptors' do
        allow(registry).to receive('get_external_deserialized_profile').and_return({ 'doc' => 'Some doc' })
        expect(registry.external_profile_dereference(uri)).to be_empty
      end

      it 'returns dereferenced hash when can be dereferenced' do
        @uri = 'http://alps.io/schema.org/DataType'
        expected_result = { 'type' => 'semantic', 'doc' => { 'html' => 'The basic data types such as Integers, Strings, etc.' } }
        expect(registry.external_profile_dereference(uri)).to eq(expected_result)
      end

    end
  end
end
