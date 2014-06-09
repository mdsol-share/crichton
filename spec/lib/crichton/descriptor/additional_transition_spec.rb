require 'spec_helper'
require 'crichton/descriptor/additional_transition'

module Crichton
  module Descriptor
    describe AdditionalTransition do
      let (:subject) { AdditionalTransition.new(@name, @url) }

      describe '#initialize' do
        it 'returns the name of transition' do
          @name = 'profile'
          expect(subject.name).to eq(@name)
        end

        it 'returns the url of transition passed as string' do
          @url = 'http://www.example.com'
          expect(subject.url).to eq(@url)
        end

        it 'returns the url of transition passed as hash' do
          @url = { 'href' => 'http://www.example.com' }
          expect(subject.url).to eq(@url['href'])
        end
      end

      describe '#safe?' do
        it 'returns true for any transition' do
          expect(subject.safe?).to be_true
        end
      end

      describe '#templated?' do
        it 'returns true for any transition' do
          expect(subject.templated?).to be_false
        end
      end

      describe '#to_a' do
        it 'returns name and url as elements of array' do
          @name = 'profile'
          @url = 'http://www.example.com'
          expect(subject.to_a).to eq(['profile', 'http://www.example.com'])
        end
      end
    end
  end
end