module Crichton
  module Tools
    class BaseErrors
      attr_reader :title, :details, :error_code, :http_status, :stack_trace, :controller

      def initialize(data = {})
        data.each { |name, value| instance_variable_set("@#{name.to_sym}", value) }
      end
    end
  end
end

