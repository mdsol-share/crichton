require 'spec_helper'
require_relative 'spec_helper'

describe 'response options', :type => :controller, integration: true do
  before do
    Crichton.reset
    Crichton.clear_config
  end

  render_views

  let(:entry) do
    get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    JSON.load(response.body)
  end

  let(:drd) do
    response = hale_request entry, 'drds', {}
    JSON.parse(response.body)["_embedded"]["items"][0]
  end

  let(:reserved_keys) { ["_links", "_embedded", "_meta"] }

  # NB: Allowing a requester to directly manipulate options is not normal.  It is a convenience for testing.
  describe 'options behavior' do
    context 'with conditions options' do
      it 'includes transitions when conditions are met' do
        response = hale_request entry, 'drds', { conditions: ["can_create"] }
        expect(JSON.parse(response.body)["_links"].keys).to include("create")
      end

      it 'filters out available transitions for unmet conditions' do
        response = hale_request entry, 'drds', { conditions: [] }
        expect(JSON.parse(response.body)["_links"].keys).to_not include("create")
      end
    end

    context 'with except options' do
      it 'does not filter data descriptors when an empty array is specified' do
        response = hale_request entry, 'drds', { except: [] }
        # total_count is the only non optional data descriptor on the drds collection
        expect(JSON.parse(response.body)).to include("total_count")
      end

      it 'filters specified data descriptors on top level objects' do
        response = hale_request entry, 'drds', { except: ["total_count"] }
        expect(JSON.parse(response.body)).to_not include("total_count")
      end

      it 'filters the data descriptors of embedded items' do
        response = hale_request entry, 'drds', { except: [] }
        # Ensure it's there before asserting its absence
        expect(JSON.parse(response.body)["_embedded"]["items"][0].keys).to include("name")
        response = hale_request entry, 'drds', { except: ["name"] }
        expect(JSON.parse(response.body)["_embedded"]["items"][0].keys).to_not include("name")
      end
    end

    context 'with only options' do
      it 'limits the response to specified data descriptors' do
        response = hale_request drd, 'self', { only: ['uuid'] }
        expect(JSON.parse(response.body).keys - reserved_keys).to eq(['uuid'])
      end
    end

    context 'with include options' do
      # TODO: This test is lame.  We should create an embeddable resource on a drd representation
      # that is not there by default, and test for the absence/presence of _embedded and the
      # key of the resource, but that requires a significant addition to the demo service
      it 'includes specified embedded resources in response' do
        response = hale_request entry, 'drds', { include: ['items'] }
        expect(JSON.parse(response.body)['_embedded'].keys).to include('items')
      end
    end

    context 'with exclude options' do
      it 'excludes specified embedded resources from the response' do
        response = hale_request entry, 'drds', { exclude: ['items'] }
        expect(JSON.parse(response.body)['_embedded']).to be_nil
      end
    end

    context 'with embed_optional options' do
      # TODO: this test suffers from the same problems as the include options test
      it 'includes optional embedded resources in the response' do
        response = hale_request entry, 'drds', { embed_optional: {embed: ['items']} }
        expect(JSON.parse(response.body)['_embedded'].keys).to include('items')
      end
    end

    context 'with additional_links options' do
      it 'dynamically adds new links to the top level resource' do
        response = hale_request entry, 'drds', { additional_links: { drad: {href: 'http://draddest.teh'}}}
        expect(JSON.parse(response.body)['_links'].keys).to include('drad')
      end
    end

    context 'with override_links options' do
      let(:new_href) { 'http://dvor.nik' }

      # TODO: override links options do not appear to work.  Spec below generates an href of
      # "http://localhost/drds?override_links[self]=http%3A%2F%2Fdvor.nik"
      xit 'overrides a defined url in the links of a response' do
        response = hale_request entry, 'drds', { override_links: { self: new_href} }
        expect(JSON.parse(response.body)['_links']['self']['href']).to eq(new_href)
      end

      it 'does not override the links of embedded items with the same rel' do
        response = hale_request entry, 'drds', { override_links: {self: new_href} }
        embedded_self_href = JSON.parse(response.body)['_embedded']['items'][0]['_links']['self']['href']
        expect(embedded_self_href).to be_a String
        expect(embedded_self_href).to_not eq(new_href)
      end
    end

    context 'with state options' do
      # TODO: Investigate this, it seems broken.  The following test will raise a Crichton::MissingState error.
      # It appears to be trying to apply the passed state to its embedded resources.  Not good.
      xit 'sets the state of a resource in a response' do
        response = hale_request entry, 'drds', { state: 'navigation' }
        # In navigation, only search and create are specified transitions (collection includes list as self)
        expect(JSON.parse(response.body)['_links'].keys).to match_array(["help", "profile", "self", "type"])
      end
    end
  end
end
