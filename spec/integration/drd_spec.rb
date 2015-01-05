require 'spec_helper'
require_relative 'shared_spec'

describe '/drd/{item}', integration: true do

  before(:all) { WebMock.disable! }
  after(:all)  { WebMock.enable!  }

  before(:each) do
    url = hale_url_for("self", drds.embedded["items"].sample)
    response = get url, {conditions: 'can_do_anything'}
    @drd = parse_hale(response.body)
  end
  require 'pry'

  #TODO less vague wording
  it 'contains descriptors' do
    expect(@drd.properties.keys).to include('name', 'status', 'kind', 'leviathan_uuid', 'created_at')
  end

  it "returns itself as a 'self'  link" do
    self_drd = parse_hale(get(transition_uri_for('self', @drd)).body)
    expect(self_drd.to_hash).to eq(@drd.to_hash)
  end

  it 'contains a profile link' do
    response = get transition_uri_for('profile', @drd), {}, {'Accept' => 'application/alps+xml'}
    expect(response.status).to eq(200)
    doc = Nokogiri::XML(response.body)
    semantic_descriptors = doc.xpath("//descriptor/@href").map { |elem| elem.to_s[0] == '#' ? elem.to_s[1..-1] : nil }
    expect(semantic_descriptors).to include(*@drd.properties.keys)
  end

  it 'contains a type link' do
    type_uri = transition_uri_for('type', @drd)
    response = get type_uri, {}, {"Accept" => "application/alps+xml"}
    expect(response.status).to eq(200)
  end

  it 'contains a help link' do
    expect(URI.parse(transition_uri_for('help', @drd))).to be_absolute
  end

  context 'the client can do anything' do
    let(:can_do_hash) { {conditions: 'can_do_anything'} }
    let(:create_url)  { hale_url_for('create', drds) }
    let(:drd_hash) { { drd: { name: 'Pike',
                              status: 'activated',
                              old_status: 'activated',
                              kind: 'standard',
                              leviathan_uuid: 'd34c78bd-583c-4eff-a66c-cd9b047417b4',
                              leviathan_url: 'http://example.org/leviathan/d34c78bd-583c-4eff-a66c-cd9b047417b4'
                            }
                      }
                    }

    it "returns itself as its 'self' link" do
      show_url = transition_uri_for('self', @drd)
      response = get show_url, can_do_hash

      self_url = transition_uri_for('self', parse_hale(response.body))
      self_response = get self_url, can_do_hash

      expect(parse_hale(response.body).to_hash).to eq(parse_hale(self_response.body).to_hash)
    end

    it 'responds idempotently to an activate call' do
      # Create deactivated drd
      req_body = { drd: {name: 'deactivated drd', status: 'deactivated', kind: 'standard'}}.merge(can_do_hash)
      response = post(create_url, req_body)

      # Get the activate URL
      drd = parse_hale(response.body)
      activate_url = hale_url_for("activate", drd)

      # Activate twice.
      put activate_url
      response = put activate_url
      expect(response.status).to eq(204)

      # Verify
      response = get hale_url_for("self", drd), can_do_hash
      expect(parse_hale(response.body).properties['status']).to eq('activated')

      # Destroy our drd
      delete hale_url_for("delete", drd)
    end

    it 'responds idempotently to a deactivate call' do
      # Create deactivated drd
      req_body = { drd: {name: 'activated drd', status: 'activated', kind: 'standard'}}.merge(can_do_hash)
      response = post(create_url, req_body)

      # Get the activate URL
      drd = parse_hale(response.body)
      deactivate_url = hale_url_for("deactivate", drd)

      # Deactivate twice.
      put deactivate_url
      response = put deactivate_url
      expect(response.status).to eq(204)

      # Verify
      response = get hale_url_for("self", drd), can_do_hash
      expect(parse_hale(response.body).properties['status']).to eq('deactivated')

      # Destroy our drd
      delete hale_url_for("delete", drd)
    end

    it 'can update' do
      # Create a drd
      response = post create_url, drd_hash.merge(can_do_hash)
      drd = parse_hale(response.body)

      # Update the drd with all permissible attributes
      expect(drd.properties['name']).to eq('Pike')
      properties = { 'status' => 'deactivated',
        'old_status' => 'activated',
        'kind' => 'sentinel',
        'size' => 'medium',
        'location' => 'Mars',
        'location_detail' => 'Olympus Mons',
        'destroyed_status' => true
      }
      response = put hale_url_for("update", drd), { drd: properties }
      expect(response.status).to eq(303)

      # Check that it is really updated
      response = get hale_url_for("self", drd)
      drd = parse_hale(response.body)

      expect(drd.properties.slice(*properties.keys)).to eq(properties)
    end

    it 'can create' do
      response = post(create_url, { drd: {name: 'Pike', status: 'activated'} })

      expect(response.status).to eq(201)

      drd = parse_hale(response.body)
      self_url = hale_url_for("self", drd)
      response = get self_url
      expect(response.status).to eq(200)
      drd = parse_hale(response.body)
      expect(drd.properties['name']).to eq('Pike')
      expect(drd.properties['status']).to eq('activated')
    end

    it 'can delete' do
      # Create a drd
      response = post create_url, drd_hash

      #Make sure it is there
      self_url = hale_url_for("self", parse_hale(response.body))
      response = get self_url, can_do_hash
      expect(response.status).to eq(200)

      #blow it up
      destroy_url = hale_url_for("delete", parse_hale(response.body))
      response = delete destroy_url
      expect(response.status).to eq(204)

      # make sure it is gone
      response = get self_url
      expect(response.status).to eq(404)
    end

  end
end
