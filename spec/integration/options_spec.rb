require 'spec_helper'
require_relative 'spec_helper'

describe '/drd/{item}', :type => :controller, integration: true do

  before do
    Crichton.reset
    Crichton.clear_config
  end
  render_views

  let(:entry) do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    JSON.load(response.body)
  end

  let(:drds_body) do
    response = hale_request entry, 'drds'
    JSON.load(response.body)
  end

  # NB: Allowing a requester to directly manipulate options is not normal.  It is a convenience for testing.
  describe 'options behavior' do
    context 'with conditions options' do
    end

    context 'with except options' do
    end

    context 'with only options' do
    end

    context 'with include options' do
    end

    context 'with exclude options' do
    end

    context 'with embed_optional options' do
    end

    context 'with additional_links options' do
    end

    context 'with override_links options' do
    end

    context 'with state options' do
    end
  end
end