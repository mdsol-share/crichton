require 'spec_helper'
require 'benchmark'

describe Crichton::Discovery::EntryPoints do
  let(:resource_uri) { "foos" }
  let(:resource_relation) {"foos"}
  let(:resource_id) {"Foo"}

  let(:entry_point) do
    Crichton::Discovery::EntryPoint.new(resource_uri, resource_relation, resource_id)
  end
  let(:instance) {described_class.new([entry_point])}

  describe '#to_media_type' do
    it 'is benchmarked' do
      [:hale_json, :hal_json, :json, :html, :xhtml].each do |media_type|
        puts "Benchmarching serializing '#{media_type}' media type:"
        Benchmark.bm do |x|
          x.report { 1000.times { instance.to_media_type(media_type) } }
        end
        puts "====================================================="
      end
    end
  end
end
