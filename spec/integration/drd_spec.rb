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
    JSON.load(response.body)['_links']['drds']
  end
  
  let(:drds_item) do
    response = _http_call entry, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    JSON.load(response.body)['_links']['items'][0]
  end  

  let(:drd_body) do
    response = _http_call drds_item, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    JSON.load(response.body)
  end  
  
  it "contains descriptors" do
    expect(drd_body).to include("uuid","name","status","kind","leviathan_uuid","built_at")
  end
  
  it "returns itself as it's 'self' link" do
    response = _http_call drd_body['_links']['self'], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    expect(JSON.load(response.body)).to eq(drd_body)
  end
  
  it "contains a profile link" do
    response = _http_call drd_body['_links']['profile'], {}, {'HTTP_ACCEPT' => 'application/alps+xml'}
    expect(response.status).to eq(200)
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
      JSON.load(response.body)['_links']['drds']
    end
    
    let(:drds_item) do
      response = _http_call entry, {conditions: 'can_do_anything'}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      JSON.load(response.body)['_links']['items'][0]
    end  
    
    let(:drd_body) do
      response = _http_call drds_item, {conditions: 'can_do_anything'}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      JSON.load(response.body)
    end  

    it "returns itself as it's 'self' link" do
      response =  _http_call drd_body['_links']['self'], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      expect(JSON.load(response.body)).to eq(drd_body)
    end
    
    it "can toggle activation" do
      status = drd_body['status']
      link_toggle = drd_body['_links']['activate'] || drd_body['_links']['deactivate']
      response =  _http_call link_toggle, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      expect(response.status).to eq(204)
      new_drd = _http_call drd_body['_links']['self'], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      new_drd = JSON.load(new_drd.body)
      link_toggle = new_drd['_links']['activate'] || new_drd['_links']['deactivate']
      response =  _http_call link_toggle, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      new_drd = _http_call drd_body['_links']['self'], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      new_drd = JSON.load(new_drd.body)
      expect(new_drd['status']).to eq(status)
    end
    
    it "can update" do
      update = drd_body['_links']['update']
      form_data = update['data'].map { |key, datum| {key => random_by_datum(datum)} }.reduce({}, :merge)
      media = {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      _http_call update, form_data, media 
      new_drd = _http_call drd_body['_links']['self'], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      new_drd = JSON.load(new_drd.body)
      expect(new_drd['kind']).to eq(form_data['kind'])
    end
    
    it "can delete" do
      _http_call drd_body['_links']['delete'], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      response = _http_call drd_body['_links']['self'], {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
      
      pending('expect(response.status).to eq(404) - When Errors are tested')
    end
    
  end
  
end