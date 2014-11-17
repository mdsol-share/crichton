require 'spec_helper'
require_relative 'spec_helper'

describe '/', :type => :controller, integration: true do
  before do
    Crichton.reset
    Crichton.clear_config
  end
  # Workaround I don't understand found in https://github.com/rspec/rspec-rails/issues/860
  render_views

  it 'gets hale' do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    expect(response.status).to eq(200)
  end

  it 'gets xhtml' do
    get '/'
    expect(response.status).to eq(200)
  end

  it "returns itself as it's 'self' link" do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds = JSON.load(response.body)['_links']['drds']['href']
    get drds, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    response_body = JSON.load(response.body)
    
    self_link = response_body["_links"]["self"]["href"]
    get self_link, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    self_doc = JSON.load(response.body)
    expect(response_body).to eq(self_doc)

  end
end
