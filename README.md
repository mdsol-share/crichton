# Crichton

Crichton is a library to simplify generating and consuming Hypermedia API responses. It has the knowledge of Hypermedia 
from the Ancients.

## Usage
Any class can be used to represent a resource by simply including the Crichton::Representor module and specifying the 
resource it represents defined in an associated _Resource Descriptor_ document:

```ruby
class DRD
  include Crichton::Representor
  
  represents :drd
  
  # Other methods ...
end
```

If the _Resource Descriptor_ document defines states for a particular resource, there are a couple of options for
defining the state on the class:

If the class has a `state` instance method (e.g., the class is state machine):

```ruby
class DRD
  include Crichton::Representor::State 
  
  represents :drd
  
  # Other methods ...
end
```

If the class implements a `state` accessor or method that is not the state of the resource, one can simply define a 
different method on the class to return the resource state:

```ruby
class Address
  include Crichton::Representor::State 
  
  represents :address
  state_method :my_state_method
  
  attr_accessor :street, :city, :state, :zip
  
  def my_state_method
   # Do something to determine the state of the resource.
  end
  
  # Other methods ...
end
```

## Contributing
See [CONTRIBUTING][] for details.

## Copyright
Copyright (c) 2013 Medidata Solutions Worldwide. See [LICENSE][] for details.

[LICENSE]: LICENSE.md
[CONTRIBUTING]: CONTRIBUTING.md
