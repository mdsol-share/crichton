require 'spec_helper'
require 'crichton/lint'

module Crichton
  module Lint
    describe DatalistsValidator do
      let(:validator) { Crichton::Lint }
      let(:filename) { lint_spec_filename(*@filename) }

      describe '#validate' do
        after do
          validation_report.should == (@errors || @warnings || @message)
        end

        def validation_report
          capture(:stdout) { validator.validate(filename) }
        end

        it 'reports errors if a datalist value is empty, or is not an array or hash' do
          @filename = %w(datalists_section_errors datalists_errors.yml)
          @errors = expected_output(:error, 'datalists.invalid_value_type', key: 'kind-list', filename: filename,
            section: :datalists, sub_header: :error) <<
            expected_output(:error, 'datalists.value_missing', key: 'mean-list')
        end
      end
    end
  end
end
