require 'spec_helper'
require 'crichton/representor'
require 'crichton/representor/factory'
require 'crichton/tools/base_errors'
require 'json_spec'

module Crichton
  module Representor
    describe 'hale-json errors' do

      let (:drds) do
        class SubErrors < Crichton::Tools::BaseErrors
          include Crichton::Representor::State
          represents :error
          def initialize(data)
            super(data)
          end

          def remedy_url
            'foo'
          end

        end
        SubErrors.new({ title: 'Not supported search term',
                        error_code: :search_term_is_not_supported,
                        http_status: 422,
                        details: 'You requested search but it is not a valid search_term',})
      end
      let(:serializer) { HaleJsonSerializer }

      describe '#as_media_type' do
        it 'returns an error body' do
          @hale = JSON.load(drds_hale_json)
          stub_example_configuration
          Crichton.initialize_registry(@document || errors_descriptor)
          expect(serializer.new(drds).as_media_type(conditions: 'can_do_anything')['details']).to eq("You requested search but it is not a valid search_term")
        end

      end
    end
  end
end
