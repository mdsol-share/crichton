require 'crichton/representor/factory'

class People
  extend Crichton::Representor::Factory
  
  def self.find(search_term)
    state, people = find_people(search_term) 

    people_collection = {
      total_count: people.count, 
      items: people
    }
    build_state_representor(people_collection, :people, {state: state})
  end
  
  private 
  
  def self.find_people(search_term)
    if search_term
      [:collection,
        Person.where('name LIKE ? or status LIKE ? or kind LIKE ?', *3.times.map { "%#{search_term}%" }).all]
    else
      [:collection,
        Person.all]
    end
  end
end
