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
        expect(JSON.parse(response.body)["_embedded"]["items"][0].keys).to include("name")
        response = hale_request entry, 'drds', { except: ["name"] }
        expect(JSON.parse(response.body)["_embedded"]["items"][0].keys).to_not include("name")
      end
    end

    context 'with only options' do
      xit 'limits the response to specified data descriptors'
    end

    context 'with include options' do
      xit 'includes specified embedded resources in response'
    end

    context 'with exclude options' do
      xit 'exludes specified embedded resources from the response'
    end

    context 'with embed_optional options' do
      xit 'includes optional embedded resources in the response'
    end

    context 'with additional_links options' do
      xit 'dynamically adds new links to the top level resource'
    end

    context 'with override_links options' do
      xit 'overrides a defined url in the links of a response'
    end

    context 'with state options' do
      xit 'sets the state of a resource in a response'
    end
  end
end