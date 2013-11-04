require 'spec_helper'
require 'crichton/representor/serializer'

module Crichton
  module Representor
    describe Serializer do
      before(:all) do
        @existing_serializers = Serializer.registered_serializers
      end
      
      after(:all) do
        # Necessary since other specs load serializers so that randomization does not cause erroneous failures
        # since registered_serializers is a class method.
        reset_serializers(@existing_serializers)
      end
      
      def create_media_type_serializer(serializer = nil)
        serializer ||= :MediaTypeSerializer
        Crichton::Representor.send(:remove_const, serializer) if Representor.const_defined?(serializer)
        reset_serializers

        eval(build_sample_serializer(serializer))
      end

      def reset_serializers(value = {})
        Serializer.instance_variable_set('@registered_serializers', value)
      end

      let(:object) do
        Class.new { include Representor }.new
      end

      context 'when subclassed' do
        context 'with serializer subclasses with well-formed names' do
          before do
            create_media_type_serializer
          end

          it 'auto registers sublclassed serializers' do
            Serializer.registered_serializers[:media_type].should == MediaTypeSerializer
          end

          it 'auto registers other media types as symbols' do
            Serializer.registered_serializers[:other_media_type].should == MediaTypeSerializer
          end

          it 'auto registers content types for media types' do
            Serializer.registered_media_types[:media_type].should == ['application/media_type']
          end
        end

        context 'with serializer subclasses with mal-formed names' do
          it 'raises an error when the name does not end in Serializer' do
            @serializer = :MediaTypeSerializers
            expect { create_media_type_serializer(@serializer) }.to raise_error(Crichton::RepresentorError,
              /Subclasses .* must follow the naming convention OptionalModule::MediaTypeSerializer.*/)
          end

          it 'raises an error when the name of serializer does not match the name of first media type' do
            @serializer = :TypeMedia11Serializer
            expect { create_media_type_serializer(@serializer) }.to raise_error(ArgumentError,
              /The first media type in the list of .*/)
          end

        end
      end

      describe '.build' do
        context 'with existing subclasses' do
          before do
            create_media_type_serializer
          end

          it 'builds serializer instances associated with a media type' do
            Serializer.build(:media_type, object).should be_instance_of(MediaTypeSerializer)
          end

          it 'raises an error if object is not a Crichton::Representor' do
            expect { Serializer.build(:media_type, mock('object')) }.to raise_error(ArgumentError,
              /^The object .* is not a Crichton::Representor.$/)
          end
        end

        it 'raises an error if the type does not have a registered serializer' do
          expect { Serializer.build(:some_media_type, object) }.to raise_error(Crichton::RepresentorError,
            /^No representor serializer is registered that corresponds to the type 'some_media_type'.$/)
        end
      end

      describe '.registered_serializers' do
        context 'without any registered serializers' do
          it 'returns an empty hash if no serializers are registered' do
            reset_serializers
            Serializer.registered_serializers.should == {}
          end
        end

        context 'with existing subclasses with well-formed names' do
          it 'returns a hash of registered serializer classes' do
            create_media_type_serializer
            Serializer.registered_serializers[:media_type].should == MediaTypeSerializer
          end
        end
      end
       
      describe '#as_media_type' do
        it 'raises an error unless overridden by a subclass' do
          create_media_type_serializer
          expect { MediaTypeSerializer.new(object).as_media_type }.to raise_error(
            /The method #as_media_type is an abstract method of the Crichton::Serializer class.*/)
        end
      end

      describe '#to_media_type' do
        it 'delegates to #as_media_type as the default behavior' do
          create_media_type_serializer
          options = mock('options') 
          serializer_instance = MediaTypeSerializer.new(object)
          serializer_instance.should_receive(:as_media_type).with(options)
          serializer_instance.to_media_type(options)
        end
      end
    end
  end
end
