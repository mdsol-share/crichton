require 'yaml'

module Lint
  def self.validate(filename)
      begin
        YAML.parse_file(filename)
      rescue Exception => exception
        puts "Unable to parse file "+filename+": "+exception.message
       return
     end

    # YAML passes, now go onto do crichton parsing
  end
end

