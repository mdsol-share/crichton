require 'spec_helper'

module Crichton
  describe Registry do
    describe '.initialize' do
      context 'with a directory of resource descriptors specified' do
        before do
          Crichton.stub(:descriptor_location).and_return(resource_descriptor_fixtures)
        end

        it 'loads resource descriptors from a resource descriptor directory if configured' do
          Registry.new.descriptor_registry.count.should == 3
        end
      end

      context 'without a directory of resource descriptors specified' do
        it 'raises an error' do
          expect { Registry.new.descriptor_registry }.to raise_error(/^No resource descriptor directory exists./)
        end
      end
    end

    describe ".register_single" do
      it "accepts a descriptor document" do
        registry = Registry.new(:automatic_load => false)
        registry.register_single(drds_descriptor)
        registry.raw_descriptor_registry.keys.should == ["drds", "drd"]
      end

      it "accepts a filename" do
        registry = Registry.new(:automatic_load => false)
        registry.register_single(drds_filename)
        registry.raw_descriptor_registry.keys.should == ["drds", "drd"]
      end
    end

    describe ".register_multiple" do
      it "accepts descriptor documents" do
        registry = Registry.new(:automatic_load => false)
        registry.register_multiple([drds_descriptor, leviathans_descriptor])
        registry.raw_descriptor_registry.keys.should == ["drds", "drd", "leviathan"]
      end

      it "accepts filenames" do
        registry = Registry.new(:automatic_load => false)
        registry.register_multiple([drds_filename, leviathans_filename])
        registry.raw_descriptor_registry.keys.should == ["drds", "drd", "leviathan"]
      end

      it "accepts a document and a filename " do
        registry = Registry.new(:automatic_load => false)
        registry.register_multiple([drds_descriptor, leviathans_filename])
        registry.raw_descriptor_registry.keys.should == ["drds", "drd", "leviathan"]
      end
    end

    describe '.register_single' do
      let(:registry) { Registry.new(:automatic_load => false) }

      it 'returns the registered resource descriptor instance' do
        registry.register_single(drds_descriptor).should be_instance_of(Crichton::Descriptor::Resource)
      end

      shared_examples_for 'a resource descriptor registration' do
        it 'registers a the child detail descriptors by id in the raw registry' do
          resource_descriptor = registry.register_single(@descriptor)

          resource_descriptor.descriptors.each do |descriptor|
            registry.raw_descriptor_registry[descriptor.id].should == descriptor
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
            'Filename invalid_filename is not valid.'
          )
        end
      end

      context 'with a hash resource descriptor as an argument' do
        before do
          @descriptor = drds_descriptor
        end

        it_behaves_like 'a resource descriptor registration'
      end

      context 'with an invalid resource descriptor' do
        let(:descriptor) { drds_descriptor.dup }

        it 'raises an error if no id is specified in the resource descriptor' do
          descriptor.delete('id')
          expect { registry.register_single(descriptor) }.to raise_error(ArgumentError)
        end

        it 'raises an error if no version is specified in the resource descriptor' do
          descriptor.delete('version')
          expect { registry.register_single(descriptor) }.to raise_error(ArgumentError)
        end
      end

      it 'raises an error when the resource descriptor is not a string or hash' do
        resource_descriptor = mock('invalid_descriptor')
        expect { registry.register_single(resource_descriptor) }.to raise_error(ArgumentError)
      end

      it 'raises an error when the resource descriptor is already registered' do
        registry.register_single(drds_descriptor)
        expect { registry.register_single(drds_descriptor) }.to raise_error(ArgumentError)
      end
    end

    describe '.raw_registry' do
      let(:registry) { Registry.new(:automatic_load => false) }

      it 'returns an empty hash hash if no resource descriptors are registered' do
        registry.raw_descriptor_registry.should be_empty
      end

      it 'returns a hash of registered descriptor instances keyed by descriptor id' do
        resource_descriptor = registry.register_single(drds_descriptor)

        resource_descriptor.descriptors.each do |descriptor|
          registry.raw_descriptor_registry[descriptor.id].should == descriptor
        end
      end
    end

    describe '.raw_registry' do
      let(:registry) { Registry.new(:automatic_load => false) }

      it 'returns an empty hash hash if no resource descriptors are registered' do
        registry.raw_descriptor_registry.should be_empty
      end

      it 'returns a hash of registered descriptor instances keyed by descriptor id' do
        resource_descriptor = registry.register_single(drds_descriptor)

        resource_descriptor.descriptors.each do |descriptor|
          # Can't use a direct comparison as we don't get the original rescriptors returned when registering
          # but we can at least test that the names match.
          registry.raw_descriptor_registry[descriptor.id].name.should == descriptor.name
        end
      end
    end

    describe '.registrations?' do
      let(:registry) { Registry.new(:automatic_load => false) }

      it 'returns false if no resource descriptors are registered' do
        registry.registrations?.should be_false
      end

      it 'returns true if resource descriptors are registered' do
        registry.register_single(drds_descriptor)
        registry.registrations?.should be_true
      end
    end
  end
end
