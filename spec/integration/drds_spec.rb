require 'spec_helper'
require_relative 'spec_helper'
require "addressable/template"

describe '/drds', :type => :controller, integration: true do

  before do
    Crichton.reset
    Crichton.clear_config
  end
  
  render_views
  
  let(:entry) do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    JSON.load(response.body)['_links']['drds']['href']
  end
  let(:drds_body) do
    get entry, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    JSON.load(response.body)
  end  
  
  it "contains the total count and items" do
    expect(drds_body['total_count']).to eq(drds_body['_links']['items'].size)
  end

  it "returns itself as it's 'self' link" do
    get drds_body['_links']['self']['href'], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    expect(JSON.load(response.body)).to eq(drds_body)
  end
  
  it "contains a profile link" do
    get drds_body['_links']['profile']['href'], {}, {'HTTP_ACCEPT' => 'application/alps+xml'}
    expect(response.status).to eq(200)
  end

  it "contains a type link" do
    get drds_body['_links']['type']['href'], {}, {'HTTP_ACCEPT' => 'application/alps+xml'}
    expect(response.status).to eq(200)
  end
  
  it "contains a help link" do
    expect(URI.parse(drds_body['_links']['help']['href'])).to be_absolute
  end

  it "has embedded resources" do
    expect(drds_body['_embedded']['items'].size).to eq(drds_body['_links']['items'].size)
  end
  
  context "is searchable" do
    let(:search_template) do
      search_data = drds_body['_links']['search']['data']
      templated = drds_body['_links']['search']['templated']
      template = Addressable::Template.new(drds_body['_links']['search']['href'])
    end
    
    it 'returns empty items with unknown key/values' do
      search_uri = search_template.expand({
                      "search_term" => 'foo',
                      "search_name" => 'bar'})
      get search_uri, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      #print JSON.load(response.body)
      expect(JSON.load(response.body)['_links']['items'].size).to eq(0)
    end
    
    it 'contains item searched for' do
      embedded_item = drds_body['_embedded']['items'][0]
      embedded_href = embedded_item['_links']['self']['href']
      search_uri = search_template.expand({
         "search_term" => embedded_item['name']}) #it being search_term is silliness
      get search_uri, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      expect(JSON.load(response.body)['_links']['items'][0]['href']).to eq(embedded_href)
    end
    
  end
  
  context 'the client can do anything' do
    let(:entry) do
      get '/', {conditions: 'can_do_anything'}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      JSON.load(response.body)['_links']['drds']['href']
    end
    
    let(:drds_body) do
      get entry, {conditions: 'can_do_anything'}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      JSON.load(response.body)
    end  
    
    it "returns itself as it's 'self' link" do
      get drds_body['_links']['self']['href'], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      expect(JSON.load(response.body)).to eq(drds_body)
    end
    
    context "when filling out the create form" do
      it "can find the create form" do
        pending('for CRUD tests')
      end
      it "has data" do
        pending('for CRUD tests')
      end
      it "can have a created form" do
        pending('for CRUD tests')
      end
    end
  end
end