require 'spec_helper'
require_relative 'shared_spec'

describe '/drds' do

  before(:all) { WebMock.disable! }
  after(:all)  { WebMock.enable!  }

  it 'contains the total count and items' do
    expect(drds.properties["total_count"]).to eq(drds.embedded["items"].count)
  end

  it "returns itself as it's 'self' link" do
    response = get transition_uri_for('self', drds)
    expect(drds.to_hash).to eq(parse_hale(response.body).to_hash)
  end

  it "contains a profile link" do
    response = get transition_uri_for('profile', drds), {}, {'Accept' => 'application/alps+xml'}
    expect(response.status).to eq(200)
  end

  it "contains a type link" do
    response = get transition_uri_for('type', drds), {},  {'Accept' => 'application/alps+xml'}
    expect(response.status).to eq(200)
  end

  it "contains a help link" do
    expect(URI.parse(transition_uri_for('help', drds))).to be_absolute
  end

  it "has embedded resources" do
    expect(drds.transitions.select { |el| el.rel == "items" }.count).to eq(drds.embedded["items"].count)
  end

  context 'with accept header application/vnd.hale+json' do
    before do
      @response = get '/drds.hale_json'
    end

    it_should_behave_like 'a response with well formed headers' do
      let(:accept) { 'application/vnd.hale+json' }
      let(:response) { @response }
    end
  end

  # TODO:  Write new specs for filtered collections
end
