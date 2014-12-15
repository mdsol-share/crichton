require 'spec_helper'
require 'crichton/descriptor/additional_transition'

module Crichton
  module Descriptor
    describe AdditionalTransition do
      let (:subject) { AdditionalTransition.new(@name, @link) }

      describe '#initialize' do
        it 'sets the name of transition' do
          @name = 'profile'
          expect(subject.name).to eq(@name)
        end

        it 'sets the url of transition passed as string' do
          @link = 'http://www.example.com'
          expect(subject.url).to eq(@link)
        end

        it 'sets the name of transition as string' do
          @name = :profile
          expect(subject.name).to be_instance_of(String)
        end

        it 'sets stringified name of the transition' do
          @name = :profile
          expect(subject.name).to eq('profile')
        end
      end

      describe '#safe?' do
        it 'returns true for any transition' do
          expect(subject.safe?).to be true
        end
      end

      describe '#url' do
        it 'returns the url of transition passed as hash with key passed as string' do
          @link = { 'href' => 'http://www.example.com' }
          expect(subject.url).to eq(@link['href'])
        end

        it 'sets the url of transition passed as hash with key passed as symbol' do
          @link = { href: 'http://www.example.com' }
          expect(subject.url).to eq(@link[:href])
        end
      end

      describe '#templated?' do
        it 'returns false if templated property value is not boolean' do
          @link = { 'templated' => 'yes' }
          expect(subject.templated?).to be false
        end

        it 'returns false if templated property is not specified' do
          @link = { 'href' => 'http://www.example.org' }
          expect(subject.templated?).to be false
        end

        it 'returns false if link provided is string' do
          @link = 'http://www.example.org'
          expect(subject.templated?).to be false
        end

        it 'returns true if templated property is true' do
          @link = { 'templated' => true }
          expect(subject.templated?).to be true
        end
      end

      describe '#to_a' do
        it 'returns name and url as elements of array' do
          @name = 'profile'
          @link = 'http://www.example.com'
          expect(subject.to_a).to eq(['profile', 'http://www.example.com'])
        end
      end
    end
  end
end
