module ActionController
  class Responder
    def navigation_behavior(error)
      if request.env['HTTP_ACCEPT'] && request.env['HTTP_ACCEPT'].include?('text/html')
        options.merge!(semantics: :styled_microdata)
      end

      if get?
        display resource
      elsif post?
        display resource, status: :created, location: api_location
      else
        head :no_content
      end
    end
  end
end
