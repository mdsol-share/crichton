module ActionController
  class Responder
    CRICHTON_FORMATS = [:html, :xhtml]

    alias :original_default_render :default_render

    def default_render
      original_default_render
    rescue ActionView::MissingTemplate => e
      if get? && resource.is_a?(Crichton::Representor) && CRICHTON_FORMATS.include?(format)
        api_behavior(e)
      else
        raise e
      end
    end
  end
end

