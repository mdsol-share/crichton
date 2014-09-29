require 'crichton/tools/base_errors'

class Error < Crichton::Tools::BaseErrors
  include Crichton::Representor::State
  represents :error

  def initialize(data)
    super(data)
  end
end
