require 'spec_helper'
require 'lint'
require 'i18n'

describe Lint do

  before do
    Crichton.clear_registry
    Crichton.clear_config
    load_internationalization_file
  end
  it "displays a success statement when linting a clean resource descriptor file" do
    content = capture(:stdout) {
      Lint.validate(drds_filename)
    }
    content.should == I18n.t('aok')+"\n"
  end

  it "display a missing states section error when the states section is missing" do
    filename = lint_spec_filename('missing_sections', 'nostate_descriptor.yml')
    content = capture(:stdout) {
      Lint.validate(filename)
    }
    content.should == expected_output(OUT_TYPE::ERROR, 'catastrophic.section_missing', :section => 'states', :filename => filename)
  end

  it "display missing descriptor errors when the descriptor section is missing" do
    filename = lint_spec_filename('missing_sections', 'nodescriptors_descriptor.yml')

    errors = expected_output(OUT_TYPE::ERROR, 'catastrophic.section_missing', :section => 'descriptors', :filename => filename) <<
      expected_output(OUT_TYPE::ERROR, 'catastrophic.no_secondary_descriptors')

    content = capture(:stdout) {
      Lint.validate(filename)
    }
    content.should == errors
  end

  it "display a missing protocols section error when the protocols section is missing" do
    filename = lint_spec_filename('missing_sections', 'noprotocols_descriptor.yml')
    content = capture(:stdout) {
      Lint.validate(filename)
    }
    content.should == expected_output(OUT_TYPE::ERROR, 'catastrophic.section_missing',
                                      {:section => 'protocols', :filename => filename})
  end

  it "display warnings correlating to self: and doc: issues when they are found in a descriptor file" do
    filename = lint_spec_filename('state_section_errors', 'condition_doc_and_self_errors.yml')

    warnings = expected_output(OUT_TYPE::WARNING, 'states.no_self_property', :resource => 'drds',
                               :state => 'collection', :transition => 'list') <<
      expected_output(OUT_TYPE::WARNING, 'states.doc_property_missing', :resource => 'drd', :state => 'activated')

    content = capture(:stdout) {
      Lint.validate(filename)
    }
    content.should == warnings
  end

  it "display errors when next transitions are missing or empty" do
    filename = lint_spec_filename('state_section_errors', 'missing_and_empty_transitions.yml')

    errors =  expected_output(OUT_TYPE::ERROR, 'states.empty_missing_next', :resource => 'drds',
                              :state => 'collection', :transition => 'self') <<
      expected_output(OUT_TYPE::ERROR, 'states.empty_missing_next', :resource => 'drd',
                                    :state => 'activated', :transition => 'self')

    content = capture(:stdout) {
      Lint.validate(filename)
    }
    content.should == errors
  end

  it "display errors when next transitions are pointing to non-existent states" do
    filename = lint_spec_filename('state_section_errors', 'phantom_transitions.yml')

    errors =   expected_output(OUT_TYPE::ERROR,'states.phantom_next_property', :secondary_descriptor => 'drds',
                      :state => 'navigation', :transition => 'self',  :next_state => 'navegation') <<
      expected_output(OUT_TYPE::ERROR,'states.phantom_next_property', :secondary_descriptor => 'drd',
                            :state => 'activated', :transition => 'self',  :next_state => 'activate')

    content = capture(:stdout) {
      Lint.validate(filename)
    }
    content.should == errors
  end

  def load_internationalization_file
    I18n.load_path = [File.dirname(__FILE__)+'/../../lib/lint/eng.yml']
    I18n.default_locale = 'eng'
  end
end
