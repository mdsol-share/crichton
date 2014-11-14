require 'debugger'
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
  
  shared_examples 'with accept type' do |accept|

    HEADER_KEYS = [ 'Content-Type','Cache-Control', 'expires', 'X-UA-Compatible', 'ETag', 'X-Request-Id', 'X-Runtime', 'Content-Length' ]

    before do
      get '/', {},  {'HTTP_ACCEPT' => accept}
    end

    it 'contains the correct header keys' do
      HEADER_KEYS.each {|k| expect(response.headers.keys).to include(k)}
    end

    it 'contains accurate content-type' do
      expect(response.headers['content-type']).to eql(accept)
    end

    it 'contains accurate content-length' do
      expect(response.headers['content-length']).to eql(response.body.length.to_s)
    end
  end
  
  context 'correct response headers' do
    it_should_behave_like 'with accept type', 'application/xml'
    it_should_behave_like 'with accept type', 'application/vnd.hale+json'
    it_should_behave_like 'with accept type', 'application/hal+json'
    it_should_behave_like 'with accept type', 'text/html'
  end
  
end
