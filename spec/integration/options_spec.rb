require 'spec_helper'

describe 'response options' do

  before(:all) { WebMock.disable! }
  after(:all)  { WebMock.enable!  }

  # NB: Allowing a requester to directly manipulate options is not normal.  It is a convenience for testing.
  describe 'options behavior' do
    context 'with conditions options' do
      it 'includes transitions when conditions are met' do
        response = get '/drds', { conditions: ["can_create"] }
        expect(drds.transitions.any? { |t| t.rel == 'create' }).to be true
      end

      it 'filters out available transitions for unmet conditions' do
        response = get '/drds', { conditions: [] }
        drds = parse_hale(response.body)
        expect(drds.transitions.find { |t| t.rel == 'create' }).to be nil
      end
    end

    context 'with except options' do
      it 'does not filter data descriptors when an empty array is specified' do
        response = get '/drds', { except: [] }
        drds = parse_hale(response.body)
        # total_count is the only non optional data descriptor on the drds collection
        expect(drds.properties.keys).to include 'total_count'
      end

      it 'filters specified data descriptors on top level objects' do
        response = get '/drds', { except: ['total_count'] }
        drds = parse_hale(response.body)
        expect(drds.properties.keys).to_not include 'total_count'
      end

      # TODO: investigate cascading behavior for all options, something is off.
      xit 'filters the data descriptors of embedded items' do
        # Ensure it's there before asserting its absence
        response = get '/drds', { except: [] }
        drd = parse_hale(response.body).embedded["items"].first
        expect(drd.properties.keys).to include 'name'

        response = get '/drds', { except: ['name'] }
        expect(drd.properties.keys).to_not include 'name'
      end
    end

    context 'with only options' do
      it 'limits the response to specified data descriptors' do
        self_uri = transition_uri_for('self', drds.embedded["items"].sample)
        response = get self_uri, { only: ['name'] }
        drd = parse_hale(response.body)
        expect(drd.properties.keys).to eq(['name'])
      end
    end

    context 'with include options' do
      # TODO: This test is lame.  We should create an embeddable resource on a drd representation
      # that is not there by default, and test for the absence/presence of _embedded and the
      # key of the resource, but that requires a significant addition to the demo service
      it 'includes specified embedded resources in response' do
        expect(drds.embedded["items"]).to_not be_empty
      end
    end

    context 'with exclude options' do
      it 'excludes specified embedded resources from the response' do
        response = get '/drds.hale_json', { exclude: ['items'] }
        expect(parse_hale(response.body).embedded['items']).to be_nil
      end
    end

    context 'with embed_optional options' do
      # TODO: this test suffers from the same problems as the include options test
      it 'includes optional embedded resources in the response' do
        response = get '/drds.hale_json', { embed_optional: {embed: ['items']} }
        expect(parse_hale(response.body).embedded["items"]).to_not be_nil
      end
    end

    context 'with additional_links options' do
      it 'dynamically adds new links to the top level resource' do
        response = get '/drds.hale_json', { additional_links: { drad: {href: 'http://draddest.teh'}}}
        expect(parse_hale(response.body).transitions.any? {|t| t.rel == "drad"}).to be true
      end
    end

    context 'with override_links options' do
      # TODO: override links options do not appear to work.  Fix and spec.
      xit 'overrides a defined url in the links of a response'
      xit 'does not override the links of embedded items with the same rel'
    end

    context 'with state options' do
      # TODO: Investigate this, it seems broken.  The following test will raise a Crichton::MissingState error.
      # It appears to be trying to apply the passed state to its embedded resources.  Not good.
      xit 'sets the state of a resource in a response'
    end
  end
end
