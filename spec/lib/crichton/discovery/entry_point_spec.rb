require 'spec_helper'

describe Crichton::Discovery::EntryPoint do

  # this is not a URI, but a URI path element
  let(:resource_uri) { "foos" }
  let(:resource_relation) {"foos"}
  let(:transition_id) {"list"}
  let(:resource_id) {"Foo"}

  let(:instance) do
    described_class.new(resource_uri, resource_relation, transition_id, resource_id)
  end

  it "returns the correct resource relation" do
    expect(instance.resource_relation).to eq resource_relation
  end

  it "returns the correct resource uri" do
    expect(instance.resource_uri).to eq resource_uri
  end

  it "returns the correct transition_id" do
    expect(instance.transition_id).to eq transition_id
  end

  it "returns the correct resource_id" do
    expect(instance.resource_id).to eq resource_id
  end

  it "returns the correct url" do
    expect(instance.url).
      to eq "#{Crichton.config.deployment_base_uri}/#{resource_uri}"
  end

  it "returns the correct href" do
    expect(instance.href).
      to eq "#{Crichton.config.deployment_base_uri}/#{resource_uri}"
  end

  it "returns the same value for the url and the href" do
    expect(instance.url).to eq instance.href
  end

  it "returns the correct name" do
    expect(instance.name).to eq resource_relation
  end

  it "returns the same value for name as resource relation" do
    expect(instance.name).to eq instance.resource_relation
  end

  it "returns the correct rel value" do
    expect(instance.rel).
      to eq sprintf('%s/%s#%s', Crichton.config.alps_base_uri, resource_id, transition_id)
  end

  it "returns the correct link_relation" do
    expect(instance.link_relation).
      to eq sprintf('%s/%s#%s', Crichton.config.alps_base_uri, resource_id, resource_relation)
  end

  it "is a kind of Crichton::Representor" do
    expect(instance).to be_kind_of Crichton::Representor
  end
end
