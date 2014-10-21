require 'uuid_base'

class Drd < UuidBase
  include Crichton::Representor::State
  represents :drd
  state_method :status
  
  def activate
    self.status = 'activated'
    save
  end

  def deactivate
    self.status = 'deactivated'
    save
  end
end
