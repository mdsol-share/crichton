require 'spec_helper'

describe Crichton::Discovery::EntryPoint do

  # this is not a URI, but a URI path element
  let(:resource_uri_path) { "foos" }
  let(:resource_name) {"foos"}
  let(:resource_id) {"Foo"}

  let(:instance) do
    described_class.new(resource_uri_path, resource_name, resource_id)
  end

  it "returns the correct href" do
    expect(instance.href).
      to eq "#{Crichton.config.deployment_base_uri}/#{resource_uri_path}"
  end

  it "returns the correct name" do
    expect(instance.name).to eq resource_name
  end

  it "returns the correct link_relation" do
    expect(instance.link_relation).
      to eq sprintf('%s/%s#%s', Crichton.config.alps_base_uri, resource_id, resource_name)
  end
end
