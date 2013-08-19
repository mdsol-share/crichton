require 'spec_helper'
require 'lint'

describe Lint do
  before do
    Crichton.clear_registry
    Crichton.clear_config
  end

 it "displays a success statement when linting a clean resource descriptor file" do
   content = capture(:stdout) {
    Lint.validate(drds_filename)
   }
   content.should == "resource descriptor file passes lint validation.\n"
 end

  it "display a missing states section error when the states section is missing" do
    filename = lint_spec_filename('missing_sections', 'nostate_descriptor.yml')
    content = capture(:stdout) {
     Lint.validate(filename)
    }
    content.should == ("\tERROR: states section missing from " << filename << " descriptor file\n")
  end

  it "display missing descriptor errors when the descriptor section is missing" do
    filename = lint_spec_filename('missing_sections', 'nodescriptors_descriptor.yml')

    error1 = "\tERROR: descriptors section missing from " << filename << " descriptor file\n"
    error2 =  "\tERROR:  At least one resource type must be defined (e.g. object, collection, etc.) in states: and descriptors: sections\n"
    errors = error1+ error2

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
    content.should == ("\tERROR: protocols section missing from " << filename << " descriptor file\n")
  end

  it "display errors correlating to self: and doc: errors when they are found in a descriptor file" do
    filename = lint_spec_filename('state_section_errors', 'condition_doc_and_self_errors.yml')

    error1 = "\tERROR: descriptors section missing from " << filename << " descriptor file\n"
    error2 =  "\tERROR:  At least one resource type must be defined (e.g. object, collection, etc.) in states: and descriptors: sections\n"
    errors = error1+ error2

    content = capture(:stdout) {
     Lint.validate(filename)
    }
    content.should == errors
  end

end
