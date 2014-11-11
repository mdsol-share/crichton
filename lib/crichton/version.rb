# Used to prevent the class/module from being loaded more than once
unless defined?(::Crichton::VERSION)
  module Crichton
    module VERSION
      MAJOR = 0
      MINOR = 1
      TINY  = 0
    
      STRING = [MAJOR, MINOR, TINY].join('.')
    end
  end
end
