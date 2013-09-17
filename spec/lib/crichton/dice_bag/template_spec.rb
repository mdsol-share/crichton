require 'spec_helper'
require 'crichton/dice_bag/template'

module Crichton 
  module DiceBag
    describe Template do
      describe '#tempates_location' do
        it 'returns the location that templates are generated for a project' do
          Crichton.stub(:config_directory).and_return('config_directory')
          subject.templates_location.should == 'config_directory'
        end
      end
  
      describe '#tempates' do
        it 'returns an array of templates' do
          subject.templates.first.should =~ /crichton.yml.dice$/
        end
      end
    end
  end
end
