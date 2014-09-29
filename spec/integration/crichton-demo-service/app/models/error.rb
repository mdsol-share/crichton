class Error
  include Crichton::Representor::State
  represents :error
  attr_reader :title, :details, :error_code, :http_status, :stack_trace, :controller

  def initialize(data = {})
    data.each { |name, value| instance_variable_set("@#{name.to_sym}", value) }
  end

  def describes_url
    controller.request.path
  end
end