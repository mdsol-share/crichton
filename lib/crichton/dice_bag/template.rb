require 'crichton'
require 'dice_bag'

module Crichton
  module DiceBag
    class Template < ::DiceBag::AvailableTemplates
      def templates_location
        Crichton.config_directory
      end
    
      def templates
        [File.join(File.dirname(__FILE__), 'crichton.yml.dice')]
      end
    end
  end
end
