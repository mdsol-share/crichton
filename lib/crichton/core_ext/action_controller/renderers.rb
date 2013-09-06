require 'crichton/representor/serializer'

module ActionController
  module Renderers
    def self.register_mime_type(mime_type, content_types)
      Mime::Type.register content_types.shift, mime_type, content_types
    end

    Crichton::Representor::Serializer.registered_mime_types.each { |mime_type, content_types|
      add mime_type do |obj, options|
        type = mime_type
        obj.respond_to?(:to_media_type) ? obj.to_media_type(type, options) : obj
      end

      register_mime_type(mime_type, content_types) if not mime_type.to_s.include?("html")
    }
  end

  Mime::Type.unregister :html
  Mime::Type.register "text/html", :html
  Mime::Type.register "application/xhtml+xml", :xhtml
end
