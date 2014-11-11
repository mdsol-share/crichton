require 'spec_helper'
require_relative 'spec_helper'
require "addressable/template"
require 'rexml/document'

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
  
  let(:drds_item) do
    response = hale_request entry, 'drds'
    JSON.load(response.body)['_links']['items'][0]
  end  

  let(:drd_body) do
    response = hale_request drds_item
    JSON.load(response.body)
  end  
  
  it "contains descriptors" do
    expect(drd_body).to include("uuid","name","status","kind","leviathan_uuid","built_at")
  end
  
  it "returns itself as it's 'self' link" do
    response = hale_request drd_body, 'self'
    expect(JSON.load(response.body)).to eq(drd_body)
  end
  
  it "contains a profile link" do
    response = _http_call drd_body['_links']['profile'], {}, {'HTTP_ACCEPT' => 'application/alps+xml'}
    expect(response.status).to eq(200)
    doc = Nokogiri::XML(response.body)
    semantic_descriptors = doc.xpath("//descriptor/@href").map {|elem| elem.to_s[0] == '#' ? elem.to_s[1..-1] : nil}
    fields = drd_body.keys - %w[_links _meta _embedded]
    expect(semantic_descriptors).to include(*fields)
  end
  
  it "contains a type link" do
    response = _http_call drd_body['_links']['type'], {}, {'HTTP_ACCEPT' => 'application/alps+xml'}
    expect(response.status).to eq(200)
  end
  
  it "contains a help link" do
    expect(URI.parse(drd_body['_links']['help']['href'])).to be_absolute
  end

  context 'the client can do anything' do
    
    let(:entry) do
      get '/', {conditions: 'can_do_anything'}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      JSON.load(response.body)
    end
    
    let(:drds_item) do
      response = hale_request entry, 'drds', {conditions: 'can_do_anything'}
      JSON.load(response.body)['_links']['items'][0]
    end  
    
    let(:drd_body) do
      response = hale_request drds_item, false, {conditions: 'can_do_anything'}
      JSON.load(response.body)
    end  

    it "returns itself as it's 'self' link" do
      response =  hale_request drd_body, 'self'
      expect(JSON.load(response.body)).to eq(drd_body)
    end
    
    it "can toggle activation" do
      link_toggle = ->(drd_doc) { drd_doc['_links']['activate'] ? 'activate' : 'deactivate' }
      status = drd_body['status']
      response =  hale_request drd_body, link_toggle.(drd_body)
      expect(response.status).to eq(204)
      new_drd = hale_request drd_body, 'self'
      new_drd = JSON.load(new_drd.body)
      expect(new_drd['status']).not_to eq(status)
      response =  hale_request new_drd, link_toggle.(new_drd)
      new_drd = hale_request new_drd, 'self'
      new_drd = JSON.load(new_drd.body)
      expect(new_drd['status']).to eq(status)
    end
    
    it "can update" do
      form_data = drd_body['_links']['update']['data'].map { |key, datum| {key => random_by_datum(datum)} }.reduce({}, :merge)
      media = {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      hale_request drd_body, 'update', form_data
      new_drd = hale_request drd_body, 'self'
      new_drd = JSON.load(new_drd.body)
      expect(new_drd['kind']).to eq(form_data['kind'])
    end
    
    it "can delete" do
      hale_request drd_body, 'delete'
      response = hale_request drd_body, 'self'
      expect(response.status).to eq(404)
      hale_response = JSON.load(response.body)
      expect(hale_response['title']).to eq("Item not found")
      expect(hale_response['_links']).to include('describes', 'profile', 'type', 'help')
    end
    
  end
  
end
