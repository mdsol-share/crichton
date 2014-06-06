require 'spec_helper'
require 'crichton/configuration'

module Crichton
  describe Configuration do
    let(:configuration) { Configuration.new(@config || example_environment_config) }

    describe 'crichton_proxy_base_uri' do
      it 'returns the crichton_proxy base URI' do
        expect(configuration.crichton_proxy_base_uri).to eq('http://example.org/crichton')
      end
    end

    describe '#resource_home_response_expiry' do
      context 'when configured' do
        it 'returns the resource home response expiry' do
          expect(configuration.resource_home_response_expiry).to eq({ 'expiry' => 40 })
        end
      end

      context 'when not configured' do
        it 'returns default resource home response expiry' do
          @config = example_environment_config.except('resource_home_response_expiry')
          expect(configuration.resource_home_response_expiry).to eq({ 'expiry' => 20 })
        end
      end
    end

    describe '#alps_profile_response_expiry' do
      context 'when configured' do
        it 'returns the alps profile response expiry' do
          expect(configuration.alps_profile_response_expiry).to eq({'expiry' => 40})
        end
      end

      context 'when not configured' do
        it 'returns default alps profile response expiry' do
          @config = example_environment_config.except('alps_profile_response_expiry')
          expect(configuration.alps_profile_response_expiry).to eq({'expiry' => 20})
        end
      end
    end

    %w(alps deployment discovery documentation).each do |attribute|
      describe "\##{attribute}_base_uri" do
        it "returns the #{attribute} base URI" do
          expect(configuration.send("#{attribute}_base_uri")).to eq("http://#{attribute}.example.org")
        end
      end
    end

    %w(js css).each do |attribute|
      describe "\##{attribute}_uri" do
        it "returns the #{attribute}_uri as Array" do
          expect(configuration.send("#{attribute}_uri")).to be_a(Array)
        end

        it "returns the #{attribute}_uri array with the expected content" do
          expect(configuration.send("#{attribute}_uri")).to match_array(["http://example.org/resources/#{attribute}.#{attribute}"])
        end
      end
    end
  end
end
