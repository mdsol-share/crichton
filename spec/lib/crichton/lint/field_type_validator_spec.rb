require 'spec_helper'
require 'crichton/lint'

describe Crichton::Lint::FieldTypeValidator do
  let(:validator) { Crichton::Lint }
  let(:filename) { create_drds_file(@descriptor, LINT_FILENAME) }

  before do
    allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).and_return('<alps></alps>')
    @descriptor = drds_descriptor
  end

  describe '#validate' do
    after do
      expect(validation_report(filename)).to eq(@errors || @warnings || @message)
    end
    
    it 'reports an invalid field type error' do
      @descriptor['idempotent']['update']['data'][0]['field_type'] = 'invalid_type'
      @errors = expected_output(:error, 'descriptors.invalid_field_type', id: 'status', field_type: 'invalid_type',
        filename: filename, section: :descriptors, sub_header: :error) << 
         expected_output(:error, 'descriptors.invalid_field_type', id: 'status', field_type: 'invalid_type')
    end
    
    it 'reports a nonexistent validator error' do
      @descriptor['extensions']['validated_input_field']['validators'] << 'nonexistent_validator'
      @errors = expected_output(:error, 'descriptors.invalid_field_validator', id: 'name', field_type: 'text', validator: 'nonexistent_validator',
        filename: filename, section: :descriptors, sub_header: :error)
    end
    
    it 'reports a restricted validator error' do
      @descriptor['extensions'].merge!({"validated_input_field"=>{"field_type"=>"time", "validators"=>["maxlength"]}})
      @errors = expected_output(:error, 'descriptors.not_permitted_field_validator', id: 'name', field_type: 'time', validator: 'maxlength',
        filename: filename, section: :descriptors, sub_header: :error)
    end
    
    it 'reports a success statement with a clean file' do
      @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
    end
  end
end