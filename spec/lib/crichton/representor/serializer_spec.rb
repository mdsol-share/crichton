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
        Class.new do
          include Representor
          represents :drd
        end.new
      end

      context 'when subclassed' do
        context 'with serializer subclasses with well-formed names' do
          before do
            create_media_type_serializer
          end

          it 'auto registers sublclassed serializers' do
            expect(Serializer.registered_serializers[:media_type]).to eq(MediaTypeSerializer)
          end

          it 'auto registers other media types as symbols' do
            expect(Serializer.registered_serializers[:other_media_type]).to eq(MediaTypeSerializer)
          end

          it 'auto registers content types for media types' do
            expect(Serializer.registered_media_types[:media_type]).to eq(['application/media_type'])
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
            expect(Serializer.build(:media_type, object)).to be_instance_of(MediaTypeSerializer)
          end

          it 'raises an error if object is not a Crichton::Representor' do
            expect { Serializer.build(:media_type, double('object')) }.to raise_error(ArgumentError,
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
            expect(Serializer.registered_serializers).to eq({})
          end
        end

        context 'with existing subclasses with well-formed names' do
          it 'returns a hash of registered serializer classes' do
            create_media_type_serializer
            expect(Serializer.registered_serializers[:media_type]).to eq(MediaTypeSerializer)
          end
        end
      end

      describe '#response_headers' do
        it 'returns comma-separated slt header' do
          create_media_type_serializer
          request = double('request')
          request.stub(:scheme).and_return('http')
          request.stub(:[]).with(:controller).and_return('drds')
          request.stub(:[]).with(:action).and_return('index')
          expected_result = { 'REQUEST_SLT' => '99th_percentile=100ms,std_dev=25ms,requests_per_second=50' }
          object.stub(:self_transition).and_return(nil)
          expect(MediaTypeSerializer.new(object).response_headers(object, request)).to eq(expected_result)
        end
      end
    end
  end
end
