module ActionController
  class Responder
    def navigation_behavior(error)
      options.merge!(:semantics => :styled_microdata) if request.env["HTTP_ACCEPT"].to_s.include?("text/html")
      if get?
        display resource
      elsif post?
        display resource, :status => :created, :location => api_location
      else
        head :no_content
      end
    end
  end
end
