require 'spec_helper'
require 'benchmark'

# This performance spec is temporary until the representers gem is integrated into Crichton. When this happens
# we can solely rely on the benchmark rake task provided by representers.
describe Crichton::Discovery::EntryPoints do
  let(:resource_uri) { "foos" }
  let(:resource_relation) {"foos"}
  let(:resource_id) {"Foo"}

  let(:entry_point) do
    Crichton::Discovery::EntryPoint.new(resource_uri, resource_relation, resource_id)
  end
  let(:instance) {described_class.new([entry_point])}

  ITERATIONS = 3
  OP_COUNT = 10000

  describe '#to_media_type' do
    it 'is benchmarked' do
      [:hale_json, :hal_json, :json, :html, :xhtml].each do |media_type|
        puts "Benchmarching serializing '#{media_type}' media type:"
        results = Benchmark.bm do |x|
          1.upto(ITERATIONS) do |i|
            x.report { OP_COUNT.times { instance.to_media_type(media_type) } }
          end
        end

        average_total_times = results.map(&:total).inject(&:+) / ITERATIONS
        average_operation_ms = (average_total_times * 1000) / OP_COUNT

        puts "Invoked to_media_type #{OP_COUNT} times on a complex documents which took on average #{'%.4f' % average_total_times} seconds"
        puts "It took #{'%.4f' % average_operation_ms} milliseconds total for each document"
        puts "====================================================="
      end
    end
  end
end
