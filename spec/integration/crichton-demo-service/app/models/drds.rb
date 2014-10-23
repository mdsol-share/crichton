require 'crichton/representor/factory'

class Drds
  extend Crichton::Representor::Factory
  
  def self.find(search_term)
    state, drds = find_drds(search_term) 

    drds_collection = {
      total_count: drds.count, 
      items: drds
    }
    build_state_representor(drds_collection, :drds, {state: state})
  end
  
  private 
  
  def self.find_drds(search_term)
    if search_term
      [:navigation,
        Drd.where('name LIKE ? or status LIKE ? or kind LIKE ?', *3.times.map { "%#{search_term}%" }).all]
    else
      [:collection,
        Drd.all]
    end
  end
end
