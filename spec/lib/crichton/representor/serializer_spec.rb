require 'spec_helper'
require 'crichton/representor/serializer'

module Crichton
  module Representor
    describe Serializer do
      def clear_serializers
        Serializer.instance_variable_set('@registered_serializers', {})
      end
      
      def clear_media_type_serializer(serializer = nil)
        Crichton::Representor.send(:remove_const, serializer || :MediaTypeSerializer)
        clear_serializers
      end
      
      def create_media_type_serializer(serializer = nil)
        eval("class #{serializer || 'MediaTypeSerializer'} < Crichton::Representor::Serializer; end")
      end
      
      def wrap(example)
        create_media_type_serializer
        example.run
        clear_media_type_serializer
      end
      
      let(:object) do
        Class.new { include Representor }.new
      end
      
      context 'when subclassed' do
        context 'with serializer subclasses with well-formed names' do
          around do |example|
            wrap(example)
          end

          it 'auto registers sublclassed serializers' do
            Serializer.registered_serializers[:media_type].should == MediaTypeSerializer
          end
        end
        
        context 'with alternate media types defined for the serializer' do
          it 'auto registers alternate media types' do
            eval("class MediaTypeSerializer < Crichton::Representor::Serializer; alternate_media_types " <<
              ":alt_media_type, 'other_alt_media_type'; end")
            Serializer.registered_serializers[:alt_media_type].should == MediaTypeSerializer
            Serializer.registered_serializers[:other_alt_media_type].should == MediaTypeSerializer
          end
        end
  
        context 'with serializer subclasses with mal-formed names' do
          after do
            clear_media_type_serializer(@serializer)
          end
          
          it 'raises an error when the name does not end in Serializer' do
            @serializer = :MediaTypeSerializers
            expect { create_media_type_serializer(@serializer) }.to raise_error(Crichton::Representor::Error,
              /Subclasses .* must follow the naming convention OptionalModule::MediaTypeSerializer.*/)
          end
        end
      end

      describe '.build' do
        context 'with existing subclasses' do
          around do |example|
            wrap(example)
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
          expect { Serializer.build(:some_media_type, object) }.to raise_error(Crichton::Representor::Error,
            /^No representor serializer is registered that corresponds to the type 'some_media_type'.$/)
        end
      end
      
      describe '.registered_serializers' do
        around do |example|
          clear_serializers
          example.run
          clear_serializers
        end
        
        it 'returns an empty hash if no serializers are registered' do
          Serializer.registered_serializers.should == {}
        end
        
        context 'with existing subclasses with well-formed names' do
          around do |example|
            wrap(example)
          end
          
          it 'returns a hash of registered serializer classes' do
            Serializer.registered_serializers[:media_type].should == MediaTypeSerializer
          end
        end
      end
    end
  end
end
