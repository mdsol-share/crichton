require 'spec_helper'

module Crichton 
  module DiceBag
    describe Template do
      describe '#tempates_location' do
        it 'returns the config_directory' do
          Crichton.stub(:config_directory).and_return('config_directory')
          Template.new.templates_location.should == 'config_directory'
        end
      end
  
      describe '#tempates_location' do
        it 'returns the config_directory' do
          Template.new.templates.first.should =~ /crichton.yml.dice$/
        end
      end
    end
  end
end
