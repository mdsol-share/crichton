require 'spec_helper'
require 'crichton/descriptor/response_headers'

module Crichton
  module Descriptor
    describe ResponseHeaders do
      let(:target) { double('target') }
      let(:response_headers) { ResponseHeaders.new(@descriptor, target) }

      describe '#to_h' do
        it 'returns response_headers content when source is local' do
          @descriptor = { 'Cache-Control' => 'no-cache' }
          response_headers.to_h.should == @descriptor
        end

        context 'when descriptor points to external source' do
          before do
            @descriptor = { 'external' => { 'source' => 'method_on_target' } }
          end

          it 'returns empty hash when method does not exist on target' do
            response_headers.to_h.should == {}
          end

          it 'raises an error when method call result on target is not a hash' do
            target.stub(:method_on_target) { 'result' }
            expect { response_headers.to_h }.to raise_error( Crichton::TargetMethodResponseError )
          end

          it 'returns a hash as a result from method call on target' do
            result = { 'Cache-Control' => 'no-cache' }
            target.stub(:method_on_target) { result }
            response_headers.to_h.should == result
          end
        end
      end
    end
  end
end
