require 'spec_helper'
require_relative 'spec_helper'
require "addressable/template"
describe '/', :type => :controller, integration: true do

  before do
    Crichton.reset
    Crichton.clear_config
  end
  
  render_views
  
  it "contains the total count and items" do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds = JSON.load(response.body)['_links']['drds']['href']
    get drds, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds_body = JSON.load(response.body)

    expect(drds_body['total_count']).to eq(drds_body['_links']['items'].size)
  end
  
  it "contains a profile link" do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds = JSON.load(response.body)['_links']['drds']['href']
    get drds, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds_body = JSON.load(response.body)

    get drds_body['_links']['profile']['href'], {}, {'HTTP_ACCEPT' => 'application/alps+xml'}
    expect(response.status).to eq(200)
  end
  
  it "contains a type link" do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds = JSON.load(response.body)['_links']['drds']['href']
    get drds, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds_body = JSON.load(response.body)

    get drds_body['_links']['type']['href'], {}, {'HTTP_ACCEPT' => 'application/alps+xml'}
    expect(response.status).to eq(200)
  end
  
  it "contains a help link" do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds = JSON.load(response.body)['_links']['drds']['href']
    get drds, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds_body = JSON.load(response.body)

    get drds_body['_links']['help']['href']
    expect(response.status).to eq(200)
  end
  
  it "allows searching" do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds = JSON.load(response.body)['_links']['drds']['href']
    get drds, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds_body = JSON.load(response.body)

    template = Addressable::Template.new(drds_body['_links']['search']['href'])
    query = template.expand({search_term: 'foo'})
    get query, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    expect(JSON.load(response.body)['total_count']).to eq(0)
  end
  

  it "has embedded resources" do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds = JSON.load(response.body)['_links']['drds']['href']
    get drds, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds_body = JSON.load(response.body)

    expect(drds_body['_embedded']['items'].size).to eq(drds_body['_links']['items'].size)
  end
end