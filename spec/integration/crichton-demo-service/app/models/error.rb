require 'crichton/tools/base_errors'

class Error < Crichton::Tools::BaseErrors
  include Crichton::Representor::State
  represents :errors
  attr_reader :title, :details, :error_code, :http_status, :stack_trace, :controller

  def initialize(data)
    super(data)
  end

  def describes_url
    controller.request.path
  end
end