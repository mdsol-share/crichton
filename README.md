# Crichton

[![Build Status](https://travis-ci.org/mdsol/crichton.svg)](https://travis-ci.org/mdsol/crichton)

Crichton is a library to simplify generating and consuming Hypermedia API responses. It has the knowledge of Hypermedia 
from the Ancients.

Checkout the [Documentation][] for more info.

NOTE: THIS IS UNDER HEAVY DEV AND IS NOT READY TO BE USED YET

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
## Crichton Lint

Developing a Hypermedia aware resource, whose behavior is structured within a resource descriptor
document, may appear daunting at first and the development of a well structured and logically correct
resource descriptor document may take several iterations.

To help with the development, a lint feature is part of Crichton in order to help catch major and
minor errors in the design of the resource descriptor document.

Single or multiple descriptor files can be validated via lint through the rdlint gem executable or rake. For example:

`bundle exec rdlint -a (or --all) ` Lint validate all files in the resource descriptor directory

`bundle exec rake crichton:lint[all]` Use rake to validate all files in the resource descriptor directory

To understand all of the details of linting descriptors files, please view the [Lint README Page](doc/lint.md)

### Logging
If you use Rails, then the ```Rails.logger``` should be configured automatically.
If no logger is configured, the current behavior is to log to STDOUT. You can override it by calling
```Crichton.logger = Logger.new("some logging sink")```
early on. This only works before the first use of the logger - for performance reasons the logger
object is cached.

## Contributing
See [CONTRIBUTING][] for details.

## Copyright
Copyright (c) 2013 Medidata Solutions Worldwide. See [LICENSE][] for details.

[CONTRIBUTING]: CONTRIBUTING.md
[Documentation]: http://rubydoc.info/github/mdsol/crichton
[LICENSE]: LICENSE.md
