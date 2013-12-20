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
          transition_ids = %w(list list show)
          resource_ids = %w(DRDs EntryPoints Leviathans)

          [0,1,2].map do |i|
            resources << Crichton::Discovery::EntryPoint.new(resource_uris[i], resource_rels[i], transition_ids[i],
              resource_ids[i])
          end
          Crichton::Discovery::EntryPoints.new(resources)
        end

        def self.html_document
        "<!DOCTYPE html><html xmlns=\"http://www.w3.org/1999/xhtml\"><head><link rel=\"stylesheet\" " <<
          "href=\"http://example.org/resources/styles.css\"/><style>*[itemprop]::before {\n  content: " <<
          "attr(itemprop) \": \";\n  text-transform: capitalize\n}\n</style></head><body><ul><li/><p/><b>Rel: " <<
          "</b><a rel=\"http://alps.example.org/DRDs/#list\" href=\"http://alps.example.org/DRDs/#list\">" <<
          "http://alps.example.org/DRDs/#list</a><b>  Url:  </b><a rel=\"http://deployment.example.org/drds\" " <<
          "href=\"http://deployment.example.org/drds\">http://deployment.example.org/drds</a><li/><p/><b>Rel: " <<
          "</b><a rel=\"http://alps.example.org/EntryPoints/#list\" href=\"http://alps.example.org/EntryPoints" <<
          "/#list\">http://alps.example.org/EntryPoints/#list</a><b>  Url:  " <<
          "</b><a rel=\"http://deployment.example.org/apis\" href=\"http://deployment.example.org/apis\">" <<
          "http://deployment.example.org/apis</a><li/><p/><b>Rel: </b><a rel=\"http://alps.example.org/Leviathans/" <<
          "#show\" href=\"http://alps.example.org/Leviathans/#show\">http://alps.example.org/Leviathans/#show</a><b>" <<
          "  Url:  </b><a rel=\"http://deployment.example.org/leviathans/{uuid}\" href=\"http://deployment.example." <<
          "org/leviathans/{uuid}\">http://deployment.example.org/leviathans/{uuid}</a></ul></body></html>"
        end
      end
    end
  end
end
