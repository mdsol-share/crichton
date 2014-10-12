require 'spec_helper'
require_relative 'spec_helper'
require 'rexml/document'
include REXML

describe '/', :type => :controller, integration: true do
  before do
    Crichton.reset
    Crichton.clear_config
  end
  # Workaround I don't understand found in https://github.com/rspec/rspec-rails/issues/860
  render_views

  it 'gets' do
    get '/drds'
    expect(response.status).to eq(200)
  end

  it "returns itself as it's 'self' link" do
    get '/drds', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    expect(response.status).to eq(200)
    
    first_doc = JSON.load(response.body)
    get first_doc["_links"]["self"]["href"], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    second_doc = JSON.load(response.body)
    expect(first_doc).to eq(second_doc)
  end

end
