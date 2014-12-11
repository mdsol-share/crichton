require 'spec_helper'
require 'crichton/alps/serialization'

module Crichton
  module ALPS 
    describe Serialization do
      let(:hash) { YAML.load(@resource_descriptor) }
      let(:registry) { Crichton::Registry.new(automatic_load: false) }
      let(:subject) do
        registry.register_single(hash)
        registry.raw_profile_registry['DRDs']
      end

      before(:all) do
        @resource_descriptor = <<-YAML
          id: DRDs
          doc: Describes the semantics, states and state transitions associated with DRDs.
          links:
            profile: DRDs
            help: DRDs#help
          semantics:
            name:
              href: http://alps.io/schema.org/Text
          ext:
            - id: extension
            - href: http://alps.io/schema.org/Ext
            - values:
              a: b
          idempotent:
            update:
              rt: none
              links:
                profile: DRDs#update
              parameters:
                - href: name
        YAML
      end

      describe '#alps_attributes' do
        it 'returns a hash of alps descriptor attributes' do
          expect(subject.alps_attributes).to eq({'id' => 'DRDs'})
        end
      end

      describe '#alps_descriptors' do
        it 'returns an array of alps descriptor hashes' do
          expect(subject.alps_descriptors.map { |descriptor| descriptor['id'] }).to eq(%w(name update))
        end
      end

      describe '#alps_elements' do
        it 'returns a hash of alps descriptor elements' do
          expect(subject.alps_elements).to  eq({
            "doc"=>{
              "value"=>"Describes the semantics, states and state transitions associated with DRDs."}, 
              "ext" => [{"id"=>"extension"}, {"href"=>"http://alps.io/schema.org/Ext"}, 
                {"a"=>"b", "value"=>"null", "href"=>"http://alps.io/extensions/serialized_options_list"}],
              "link"=>[
                {"rel"=>"profile", "href"=>"http://localhost:3000/alps/DRDs"}, 
                {"rel"=>"help", "href"=>"http://example.org/DRDs#help"}]})
        end
      end

      describe '#to_xml' do
        context 'when resource descriptor is in human friendly form' do
          it 'returns an XML ALPS profile structure' do
            expected_result = <<-XML
              <?xml version="1.0" encoding="UTF-8"?>
              <alps>
                <doc>
              Describes the semantics, states and state transitions associated with DRDs.  </doc>
                <ext id="extension"/>
                <ext href="http://alps.io/schema.org/Ext"/>
                <ext a="b" value="null" href="http://alps.io/extensions/serialized_options_list"/>
                <link rel="profile" href="http://localhost:3000/alps/DRDs"/>
                <link rel="help" href="http://example.org/DRDs#help"/>
                <descriptor id="name" type="semantic" href="http://alps.io/schema.org/Text">
                </descriptor>
                <descriptor id="update" type="idempotent" rt="none">
                  <link rel="profile" href="http://localhost:3000/alps/DRDs#update"/>
                  <descriptor href="#name"/>
                </descriptor>
              </alps>
            XML
            expect(subject.to_xml).to be_equivalent_to(expected_result)
          end
        end
      end

      describe '#to_alps_hash' do
        context 'without options' do
          it 'returns a hash in an ALPS profile structure' do
            expected_result =
            {
              "alps" => {
                "doc"=>{
                  "value"=>"Describes the semantics, states and state transitions associated with DRDs."}, 
                  "ext"=>[{"id"=>"extension"}, {"href"=>"http://alps.io/schema.org/Ext"}, 
                    {"a"=>"b", "value"=>"null", "href"=>"http://alps.io/extensions/serialized_options_list"}],
                  "link"=>[
                    {"rel"=>"profile", "href"=>"http://localhost:3000/alps/DRDs"}, 
                    {"rel"=>"help", "href"=>"http://example.org/DRDs#help"}], 
                  "descriptor"=>[
                    {"id"=>"name", "type"=>"semantic", "href"=>"http://alps.io/schema.org/Text"}, 
                    {
                      "link"=>[{"rel"=>"profile", "href"=>"http://localhost:3000/alps/DRDs#update"}], 
                      "id"=>"update", 
                      "type"=>"idempotent", 
                      "rt"=>"none", 
                      "descriptor"=>[{"href"=>"name"}]}]}
            }
            expect(subject.to_alps_hash).to eq(expected_result)
          end
        end
        
        describe '#to_json' do
          it 'prints the correct json' do
            result = "{\"alps\":{\"doc\":{\"value\":\"Describes the semantics, states and state transitions associated with DRDs.\"},
            \"ext\":[{\"id\":\"extension\"},{\"href\":\"http://alps.io/schema.org/Ext\"},
            {\"a\":\"b\",\"value\":\"null\",\"href\":\"http://alps.io/extensions/serialized_options_list\"}],
            \"link\":[{\"rel\":\"profile\",\"href\":\"http://localhost:3000/alps/DRDs\"},
            {\"rel\":\"help\",\"href\":\"http://example.org/DRDs#help\"}],
            \"descriptor\":[{\"id\":\"name\",\"type\":\"semantic\",\"href\":\"http://alps.io/schema.org/Text\"},
            {\"link\":[{\"rel\":\"profile\",\"href\":\"http://localhost:3000/alps/DRDs#update\"}],
            \"id\":\"update\",\"type\":\"idempotent\",\"rt\":\"none\",\"descriptor\":[{\"href\":\"name\"}]}]}}"
            expect(subject.to_json).to be_json_eql(result)
          end
        end

        context 'with top_level option false' do
          it 'returns a hash in an ALPS descriptor structure' do
            expect(subject.to_alps_hash(top_level: false)['alps']).to be_nil
          end
        end
      end

      describe 'absolute_link' do
        it 'returns the original link if it is already absolute' do
          expect(subject.send(:absolute_link, 'http://original.link.com', 'something')).to eq('http://original.link.com')
        end
      end
    end
  end
end
