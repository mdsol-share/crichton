require 'spec_helper'
require_relative 'spec_helper'

describe '/', :type => :controller, integration: true do

  # Workaround I don't understand found in https://github.com/rspec/rspec-rails/issues/860
  render_views

  it 'gets' do
    get '/'
    expect(response.status).to eq(200)
  end

end
