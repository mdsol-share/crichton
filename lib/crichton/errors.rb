module Crichton
  # Unknown state
  class MissingStateError < StandardError; end

  # Raised in Crichton::Representors that are not configured correctly in some way.
  class RepresenterError < StandardError; end

end
