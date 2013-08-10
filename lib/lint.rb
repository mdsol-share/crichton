require 'yaml'

module Lint
   MAJOR_SECTIONS = %w(states descriptors protocols)

  def self.validate(filename)
     warnings = []
     errors = []

      begin
        yml_out = YAML.load_file(filename)
      rescue Exception => exception
        puts "Unable to parse file "+filename+": "+exception.message
       return
     end

    # Using Yaml output, check for whoppers first
     MAJOR_SECTIONS.each do |section|
      if yml_out[section].nil?
        errors << "\tERROR: "+section+" section missing from "+filename+" descriptor file"
      end
     end

    if errors.any?
      errors.each do |error|
        puts error
      end
      return
    elsif warnings.any?
      warnings.each do |warning|
        puts warning
      end
    end

    # major foobars out of the way, now go onto do crichton parsing

    puts "All good with resource descriptor file "+filename
  end
end

