require 'crichton/descriptor/base'

module Crichton
  module Descriptor
    class Link < Base
      alias :rel :name
      alias :url :href
    end
  end
end
