require 'crichton/discovery/entry_point'
require 'crichton/discovery/entry_points'

module Support
  module EPHelpers
    def ep_klass
      Class.new do
        extend ::Crichton::Representor::Factory


        def self.generate_object_graph
          resources = []
          ep_attributes = %w(drds drds apis entry_points leviathans/{uuid} leviathan)
          [0,2,4].map { |i| resources << Crichton::Discovery::EntryPoint.new(ep_attributes[i], ep_attributes[i+1]) }
          Crichton::Discovery::EntryPoints.new(resources)
        end

      end
    end
  end
end
