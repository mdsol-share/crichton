module ActionController
  class Responder
    def navigation_behavior(error)
      if get?
        if resource.is_a?(Crichton::Representor)
          api_behavior(error)
        else
          raise error
        end
      elsif has_errors? && default_action
        render :action => default_action
      else
        redirect_to navigation_location
      end
    end

    def resourceful?
      return resource.respond_to?("to_#{format}") unless resource.is_a?(Crichton::Representor)
      if request.env['HTTP_ACCEPT'] && request.env['HTTP_ACCEPT'].include?('text/html')
        options.merge!(semantics: :styled_microdata)
      end
      resource.is_a?(Crichton::Representor)
    end
  end
end