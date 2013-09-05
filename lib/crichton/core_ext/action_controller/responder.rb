module ActionController
  class Responder
    def navigation_behavior(error)
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