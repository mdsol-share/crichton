module Crichton
  # Raised in Crichton::Descriptor::TransitionDecorator indicating that no state descriptor for a particular transition
  # exists.
  class MissingStateError < StandardError; end

  # Raised in Crichton::Representors that are not configured correctly in some way.
  class RepresentorError < StandardError; end

  class ExternalProfileLoadError < StandardError; end

end
