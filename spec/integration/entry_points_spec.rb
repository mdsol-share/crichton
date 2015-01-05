require 'spec_helper'
require_relative 'shared_spec'

describe '/' do

  before(:all) { WebMock.disable! }
  after(:all)  { WebMock.enable!  }

  it 'gets hale' do
    response = get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    expect(response.status).to eq(200)
  end

  xit 'gets xhtml'

  it "returns itself as it's 'self' link" do
    response = get '/', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    drds = JSON.load(response.body)['_links']['drds']['href']
    response = get '/drds.hale_json', {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    response_body = JSON.load(response.body)

    self_link = response_body["_links"]["self"]["href"]
    get self_link, {}, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
    self_doc = JSON.load(response.body)
    expect(response_body).to eq(self_doc)
  end

  ['application/xml', 'application/vnd.hale+json', 'application/hal+json', 'text/html'].each do |accept|
    context "with accept header #{accept}" do
      before do
        @response = get('/', {}, {'HTTP_ACCEPT' => accept})
      end

      it_should_behave_like 'a response with well formed headers' do
        let(:accept) {accept}
        let(:response) {@response}
      end
    end
  end

end
