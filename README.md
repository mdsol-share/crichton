# Crichton

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

Since a resource descriptor document is a .yml file, it first must meet the requirements of a
well-formed YAML file. This website is one of many to help check to see if the file is well
formed: [yaml parser] (http://yaml-online-parser.appspot.com/)

Crichton lint works to validate the logic of a single resource descriptor file, outputting errors, warning
and hints to help generate an optimal document.

Lint can be invoked in two ways, once crichton is added to your project as a gem:

### A lint gem ruby executable  (rdlint)

`bundle exec rdlint <resource desciptor file>`

The file should be a path, which is relative to the root of the project. For example, if you're in the
root of the project, you can run lint as:

`bundle exec rdlint api_descriptors/my_resource_descriptor_file.yml` (api_descriptors is a
possible standard folder to place descriptor files.)

### Running from rake

lint is also a rake task within the crichton gem. You can invoke lint with:
 `bundle exec rake crichton:lint[<resource descriptor file>]`

For those unfamiliar with rake, arguments to rake require brackets. In zsh, you must escape
the brackets with \[...\]

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
[Documentation]: http://rubydoc.info/github/mdsol/crichton/develop/file/README.md
[LICENSE]: LICENSE.md
