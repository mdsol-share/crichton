module Support
  module DRDHelpers
    def drd_klass
      Class.new do
        include ::Crichton::Representor::State
        extend ::Crichton::Representor::Factory

        represents :drd

        def self.apply_methods
          data_semantic_descriptors.each do |descriptor|
            name = descriptor.name
            define_method(name) { @attributes[name] }
          end
        end

        def self.all(options = nil)
          drds = {
              'total_count' => 2,
              'items' => 2.times.map { |i| new(i) }
          }
          build_state_representor(drds, :drds, {state: 'collection'})
        end

        def initialize(i)
          @attributes = {}
          @attributes = %w(name status kind leviathan_uuid built_at old_status location).inject({}) { |h, attr| h[attr] = "#{attr}_#{i}"; h }
          @attributes['uuid'] = i
        end

        # TODO: develop state specification options for embedded semantics
        def state
          :activated
        end

        def leviathan_url
          # Note: this is not advocating templating this, but rather just a method to demonstrate
          # the protocol implementation for URI source.
          "http://example.org/leviathan/#{leviathan_uuid}" if leviathan_uuid =~ /_1/
        end
      end
    end
  end
end