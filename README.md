# Crichton

[![Build Status](https://travis-ci.org/mdsol/crichton.svg)](https://travis-ci.org/mdsol/crichton)

Crichton is a library to simplify implementing Hypermedia APIs. It has the knowledge of Hypermedia from the Ancients.

Checkout the [Documentation][] for more info and/or try the [Demo Service](https://github.com/fosrias/crichton-demo-service).

## Overview
Crichton is opinionated that Hypermedia APIs and their associated resources should be designed and implemented as 
state-machines. As such, the library leverages a state-machine centric, declarative [_API descriptor document_][] 
which it uses to dynamically decorate data as Hypermedia representations for different media-types.

Assuming one has designed a resource as a state-machine and drafted an [_API descriptor document_][] as a canonical
definition of that resource, Crichton can be implemented in a service to return representations for
[supported media-types][].

## Models
Any class can be represented as a resource by simply including the Crichton::Representor module and specifying the 
resource that represents it:

```ruby
class DRD
  include Crichton::Representor
  
  represent_as :drd
  
  # Other methods ...
end
```

Note: This basic implementation is useful for a resource that has only one state and has no context related conditions 
(e.g. user role or permission constraints) limiting the presence of transitions (links and forms) in the representation. 
Thus, in the previous example, all available transitions will be returned in the response.

The more general case will be one of the following:
* a resource has multiple states (and possibly varying context related conditions on the transitions)
* a single state with context related conditions on the transitions

There are a couple of options for defining the state on the class:

If the class has a `state` instance method (e.g., the class is state machine):
```ruby
class DRD
  include Crichton::Representor::State 
  
  represents :drd
  
  def state
   # Do something to determine the state of the resource.
  end

  # Other methods ...
end
```
Note: If the class implements a library with a `state` method (e.g. state_machine Gem), there is no need to define a
state method. If a class does not implement a `state` instance method, but includes `Crichton::Representor` or
`Crichton::Representor::State` module, Crichton assumes that resource has only one `default` state. 
See [Resource State Descriptors](./doc/resource_descriptors.md#states-section) for more information.

If the class implements a `state` accessor or method that is not the state of the resource, one can simply define a 
different method on the class to return the resource state, if necessary:

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

### Collection Resource Misnomer
Crichton's opinion is there is no such thing as a "Collection Resource". There are just resources that include data and
transitions. Some resources may actually contain lists of other resources or be exist as a series of resources, but 
they are just a resource like any other. Thus, what some, using certain "conventions" or ORMs might consider a 
"Collection Resource", e.g. an `application/json` (non-hypermedia aware media-type) response such as:

```json
[ 
  {id: 1},
  {id: 2}
]
```

is not supported since this type of JSON response does not allow setting any attributes or metadata for a resource.
Rather, such a resource would be returned in a Hypermedia API, for example using `application/hal+json`, as:

```json
{
  "_links": {
    "self": { "href": "..." },
    "items": [ { "href": "..." }, { "href": "..." } ]
  },
  _embedded: {
    "items": [
      { 
        "_links": {
          "self": { "href": "..." }
        },
        "id": 1
      },
      { 
        "_links": {
          "self": { "href": "..." }
        },
        "id": 2
      }
    ]
  }
}
```

### Resources that embed other resources
Crichton understands and recursively builds representations of embedded representor instances. There are a number of 
approaches:
* wrapping a Hash object with a representor interface using the 
[`build_representor`](http://rubydoc.info/github/mdsol/crichton/Crichton/Representor/Factory#build_representor-instance_method)
or the 
[`build_state_representor`](http://rubydoc.info/github/mdsol/crichton/Crichton/Representor/Factory#build_state_representor-instance_method)
factory methods.
   ```ruby
   class DRDsController 
     

* creating a model for the resource
    ```ruby
    class DRDs
      include Crichton::Representor
        
      represent_as :drds
        
      def items
        @items ||= DRD.all
      end
        
      def total_count
        items.count
      end
    end
    ```
    
* using a Service Object to wrap an ORM collection object as discussed in the next section.

## Service Objects
Service Objects are a useful concept to keep models separated from logic and access controller methods in generating a
response. For example, a resource descriptor may define a `uri_source` on some protocol implementation of a transition
that it expects on an object. Alternately, one may want to apply some logic to determine conditions from the request
context to pass into a response. 

```ruby
class ServiceObject
  include Crichton::Representor::State
  
  attr_reader :target, :controller

  def initialize(target, controller)
    super(target)
    @target = target
    @controller = controller
  end
  
  def total_count
    @total_count ||= target.count
  end
  
  def items
    target
  end
  
  def some_uri_source
    controller.url_for(:some_resource)
  end
  
  alias :original_to_media_type :to_media_type
  def to_media_type(options = {})
    original_to_media_type(options.merge(state: state).merge(other_options)
  end
  
  private
  def other_options
    # Some logic to get a list of conditions or other options
  end  
  
  def state
    # Some logic to determine the state
  end
end
```

And then, in a controller:
```ruby
class ResourcesController
  respond_to(:hale_json, :hal_json, :html)
  
  def index
    resources = ServiceObject.new(DRD.all, self)
    respond_with(resources)
  end
end

## Rails
Crichton automatically registers mime types and responders for [supported media-types].

### Known Issues
* Crichton does not currently ActiveModel::Naming and thus representor instances will not set location headers unless
ActiveModel::Naming is manually implemented in the related class(es).
* Using a default format in routes.rb will prevent proper content-negotiation using headers. This appears to be a 
Rails issue. E.g. `defaults: { format: :json }` would prevent content negotiation with an Accept header 
`application/hal+json'.

## Other Frameworks
Crichton can be used to generate raw responses that can be returned in other application frameworks using the 
[#to_media_type][] interface on objects that implement `Crichton::Representor` or `Crichton::Representor::State`.

```ruby
# some_controller.rb
require 'crichton'

def media_type_symbol
  # Convert Accept type to Crichton symbol associated with media-type
end

def show
  drd = DRD.find(params[:id])
  options = #...
  drd.to_media_type(media_type_symbol, options)
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

To understand all of the details of linting descriptors files, please view the [Lint documentation](doc/lint.md).

### Logging
If you use Rails, then the `Rails.logger` should be configured automatically. If no logger is configured, the current 
behavior is to log to STDOUT. You can override it by calling `Crichton.logger = Logger.new("some logging sink")`
early on. This only works before the first use of the logger - for performance reasons the logger
object is cached.
  
## Supported Media-types
The following are currently supported media-types ([mime symbol]: [media-type])
* [html: text/html](http://www.ietf.org/rfc/rfc2854)
* [xthml: application/xhtml+xml](http://www.ietf.org/rfc/rfc3236)
* [hal_json: application/hal+json](http://tools.ietf.org/html/draft-kelly-json-hal-06)
* [hale_json: application/vnd.hale+json](https://github.com/mdsol/hale)

## Contributing
See [CONTRIBUTING][] for details.

## Acknowledgements
Thanks to [Mike Amundsen][] and [Jon Moore][] for patient explanations and the whole Hypermedia community that 
helped crystallize ideas underlying Crichton. And, of course, thanks to all the [contributors][].

## Copyright
Copyright (c) 2013 Medidata Solutions Worldwide. See [LICENSE][] for details.

[Documentation]: http://rubydoc.info/github/mdsol/crichton
[supported media-types](#[supported media-types](supported-media-types))
[_API descriptor document_]: doc/descriptors_document.md
[#to_media_type]: http://rubydoc.info/github/mdsol/crichton/Crichton/Representor/Serialization/MediaType#to_media_type-instance_method
[CONTRIBUTING]: CONTRIBUTING.md
[Documentation]: http://rubydoc.info/github/mdsol/crichton
[LICENSE]: LICENSE.md
[Mike Amundsen]: https://twitter.com/mamund
[Jon Moore]: https://twitter.com/jon_moore
[contributors]: graphs/contributors
