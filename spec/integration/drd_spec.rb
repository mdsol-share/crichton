require 'spec_helper'
require_relative 'spec_helper'
require "addressable/template"

describe '/drd/{item}', :type => :controller, integration: true do

  before do
    Crichton.reset
    Crichton.clear_config
  end
  
  render_views
  
  let(:entry) do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    JSON.load(response.body)['_links']['drds']['href']
  end
  
  let(:drds_item) do
    get entry, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    JSON.load(response.body)['_links']['items'][0]['href']
  end  

  let(:drd_body) do
    get drds_item, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    JSON.load(response.body)
  end  
  
  it "contains descriptors" do
    ["uuid","name","status","kind","leviathan_uuid","built_at"].map do |key|
      expect(drd_body).to include(key)
    end
  end
  
  it "returns itself as it's 'self' link" do
    get drd_body['_links']['self']['href'], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    expect(JSON.load(response.body)).to eq(drd_body)
  end
  
  it "contains a profile link" do
    get drd_body['_links']['profile']['href'], {}, {'HTTP_ACCEPT' => 'application/alps+xml'}
    expect(response.status).to eq(200)
  end
  
  it "contains a type link" do
    get drd_body['_links']['type']['href'], {}, {'HTTP_ACCEPT' => 'application/alps+xml'}
    expect(response.status).to eq(200)
  end
  
  it "contains a help link" do
    expect(URI.parse(drd_body['_links']['help']['href'])).to be_absolute
  end

end