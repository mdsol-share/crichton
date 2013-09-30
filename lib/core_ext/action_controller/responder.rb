module ActionController
  class Responder
    alias :old_navigation_behavior :navigation_behavior

    def navigation_behavior(error)
      if get? && resource.is_a?(Crichton::Representor)
        api_behavior(error)
      else
        old_navigation_behavior(error)
      end
    end

    alias :old_resourceful? :resourceful?
    def resourceful?
      if resource.is_a?(Crichton::Representor)
        http_accept = request.env['HTTP_ACCEPT']
        options.merge!(semantics: :styled_microdata) if http_accept && http_accept.include?('text/html')
        true
      else
        old_resourceful?
      end
    end
  end
end

