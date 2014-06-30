require 'spec_helper'

describe Crichton::Discovery::EntryPoints do

  let(:resource_uri) { "foos" }
  let(:resource_relation) {"foos"}
  let(:transition_id) {"list"}
  let(:resource_id) {"Foo"}

  let(:entry_point) do
    double('EntryPoint',
           name: resource_relation,
           link_relation: sprintf('%s/%s#%s', Crichton.config.alps_base_uri, resource_id, resource_relation),
           href: "#{Crichton.config.deployment_base_uri}/#{resource_uri}")
  end

  let(:instance) {described_class.new([entry_point])}

  describe "application/vnd.hale+json" do

    let(:expected_hale_json) do
      <<JSON
    {"_links":
       {
        "#{entry_point.link_relation}":
         {
          "href": "#{entry_point.href}",
          "name": "#{entry_point.name}"
         }
       }
    }
JSON
    end

    describe "as_media_type" do
      it "produces hale_json" do
        result = instance.as_media_type(:hale_json, {})
        expect(result).to be_json_eql(expected_hale_json)
      end
    end

    describe "to_media_type" do
      it "produces hale_json" do
        result = instance.to_media_type(:hale_json)
        expect(result).to be_json_eql(expected_hale_json)
      end
    end
  end
end
