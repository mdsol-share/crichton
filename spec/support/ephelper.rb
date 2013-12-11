require 'crichton/discovery/entry_point'
require 'crichton/discovery/entry_points'

module Support
  module EPHelpers
    def ep_klass
      Class.new do
        extend ::Crichton::Representor::Factory

        def self.generate_object_graph
          resources = []
          ep_attributes = %w(drds drds apis   )
          resource_uris = %w(drds apis leviathans/{uuid})
          resource_rels = %w(drds entry_points leviathan)
          transition_names = %w(list list show)
          resource_ids = %w(DRDs EntryPoints Leviathans)

          [0,1,2].map { |i| resources <<
            Crichton::Discovery::EntryPoint.new(resource_uris[i], resource_rels[i],
            transition_names[i], resource_ids[i]) }
          Crichton::Discovery::EntryPoints.new(resources)
        end

      end
    end
  end
end
