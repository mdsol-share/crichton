class Person < ActiveRecord::Base
  include Crichton::Representor::State
  represents :person
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
