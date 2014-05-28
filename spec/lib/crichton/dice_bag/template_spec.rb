require 'spec_helper'
require 'crichton/dice_bag/template'

module Crichton 
  module DiceBag
    describe Template do
      describe '#tempates_location' do
        it 'returns the location that templates are generated for a project' do
          allow(Crichton).to receive(:config_directory).and_return('config_directory')
          expect(subject.templates_location).to eq('config_directory')
        end
      end
  
      describe '#tempates' do
        it 'returns an array of templates' do
          expect(subject.templates.first).to match(/crichton.yml.dice$/)
        end
      end
    end
  end
end
