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

  it "is a kind of Crichton::Representor" do
    expect(instance).to be_kind_of Crichton::Representor
  end

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

  describe "text/html and application/xhtml" do

    let(:expected_markup) do
      <<MARKUP.gsub /^\s+/, ""
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head/>
 <body>
   <div itemscope="itemscope">
     <a rel="#{entry_point.link_relation}" href="#{entry_point.href}">#{entry_point.name}</a>
   </div>
  </body>
</html>
MARKUP
    end

    describe "as_media_type" do
      it "produces html" do
        #NOTE rails use the :html sym for both :html, and :xhtml
        result = instance.as_media_type(:html, {})
        expect(result).to eq expected_markup
      end
    end

    describe "to_media_type" do
      it "produces html" do
        result = instance.to_media_type(:html)
        expect(result).to eq expected_markup
      end
    end
  end
end
