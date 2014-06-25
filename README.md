# Crichton

[![Build Status](https://travis-ci.org/mdsol/crichton.svg)](https://travis-ci.org/mdsol/crichton)

Crichton is a library to simplify implementing Hypermedia APIs. It has the knowledge of Hypermedia from the Ancients.

Checkout the [documentation][] for more info and/or try the [demo service][].

## Overview
Crichton is opinionated that Hypermedia APIs and their associated resources should be designed and implemented as 
state-machines. As such, the library leverages a state-machine centric, declarative 
{file:doc/api_descriptor_documents.md _API descriptor document_} which it uses to dynamically decorate data as 
Hypermedia representations for different media-types.

Assuming one has designed a resource as a state-machine and drafted an _API descriptor document_ as a canonical
definition of that resource, Crichton can be implemented in a service to return representations for
[supported media-types][].

## Resource Design
Crichton's opinion (along with others) is that a well-defined Hypermedia API exposes a state-machine interface
that maximizes "shared understanding" of the elements in the underlying resources. Assuming one has done this design, 
there are a number of artifacts that one can develop to simplify implementing hypermedia. The following outlines the 
process and artifacts of an (overly simplified) eBook API example that illustrates underlying concepts used to create an
{file:doc/api_descriptor_documents.md _API descriptor document_} for the related resources.

### Analyze Resource Semantics
Assuming one has analysed a business problem and isolated a resource or simple set of related resources including 
determining desired properties and actions necessary to accomplish the associated work, the next step is groom the 
resource(s). This analysis is part of "Contract First" development and lays the groundwork for Hypermedia Contracts and 
State-machine analysis and definition.

Resource definition is about the best names and related meaning (semantics, or vocabulary) of the data properties and 
link relations of a resource  vs. a schema per se. Ideally, groomed resources and associated profiles that result from 
this analysis would represent the generally understandable, reusable and optimum interface for the work associated with 
the resource, such that it could be published in public profile registries with that confidence.

The {file:doc/sample_ebooks_hypermedia_contract.md Sample eBooks Hypermedia Contract} summarizes a proposed format.

### Determine Resource State-machines
Hypermedia APIs implement the Hypermedia constraint of the REST architecture style known as "hypermedia as the engine 
of application state", or HATEOAS. Implicit in this statement is the fact that Hypermedia APIs expose state-machine 
resources, that is data and available state transitions at runtime.

The {file:doc/sample_ebooks_state_machine_analysis.md Sample eBooks State-machine Analysis} gives an overview of this 
process and the artifacts it generates.

### Putting it all together
Given a solid semantic understanding of a resource, or closely related set of resources, one can use a Hypermedia
Contract and the related State-machine Analysis, an {file:doc/api_descriptor_documents.md _API descriptor document_} 
can be drafted. 

The {file:doc/sample_ebooks_api_descriptor.md Sample eBooks API Descriptor Document} aggregates the information for use 
in decorating data as resources in Crichton.

## Usage
* Checkout {file:doc/getting_started.md Getting Started}
* Design an {file:doc/api_descriptor_documents.md _API descriptor document_} and {file:doc/lint.md Lint} it
* {file:doc/know_your_options.md Know your options}
* Implement [Models](#models) and [Controllers](#controllers) (and maybe some [Service Objects](#service-objects))

## Models<a name="models"></a>
Any class can be represented as a resource by simply including the `Crichton::Representor` module and specifying the 
corresponding resource that represents it defined in an _API descriptor document_.

```ruby
class DRD
  include Crichton::Representor
  represents :drd
  
  # Other methods ...
end
```
This basic implementation is useful for a resource that has only one state and has no context related conditions 
(e.g. user role or permission constraints) limiting the presence of transitions (links and forms) in the representation. 
Thus, in the previous example, all available transitions will be returned in the response.

A more general use case will likely be one of the following:

* a single state with context related conditions on the transitions
* a resource with multiple states (and possibly varying context related conditions on the transitions)

There are a couple of options for defining the implementing state-machine functionality in Crichton:

* A class has a `state` instance method:

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
    
* A class incorporates a gem with a `state` method (e.g. state_machine Gem):

    ```ruby
    require 'state_machine'
    
    class DRD
      include Crichton::Representor::State 
      represents :drd
      
      state_machine # ...

      # Other methods ...
    end
    ```
    
* The class implements a `state` accessor or method that is not the state of the resource:

    ```ruby
    class Address
      include Crichton::Representor::State 
      represents :address
      state_method :my_state_method # Overrides the default state method name
      
      attr_accessor :street, :city, :state, :zip
      
      def my_state_method
       # Do something to determine the state of the resource.
      end
      
      # Other methods ...
    end
```

If a class does not implement a `state` instance method, but includes `Crichton::Representor` 
or `Crichton::Representor::State` module, Crichton assumes that resource has only one `default` state. 
See [Resource States](./doc/resource_descriptors.md#states) for more information.

## Controllers<a name="controllers"></a>
The simplicity of Crichton is that it implements a single interface `to_media_type` on an object which accepts a 
number of options that support dynamic decoration of the object as hypermedia. See [\#to_media_type] method for 
examples of supported options.

### Rails
Crichton automatically registers mime types and responders for [supported media-types] and hooks into the rendering
framework of Rails.

```ruby
class DRDsController < ApplicationController
  respond_to(:hale, :hal, :html, :xhtml)
  
  def show
    drd = Drd.find(params[:id])
    respond_with(drd, conditions: context_based_conditions)
  end
  
  private
  def context_based_conditions
    # Returns condition strings in API Descriptor to dynamically filter available 
    # transitions based on the context of request.
  end
end
```
  
#### Known Rails Issues
* Crichton does not currently support ActiveModel::Naming and thus representor instances will not set location headers 
unless ActiveModel::Naming is manually implemented in the related class(es).
* Using a default format in routes.rb will prevent proper content-negotiation using headers. This appears to be a 
Rails issue. E.g. `defaults: { format: :json }` would prevent content negotiation with an Accept header 
`application/hal+json'.

### Other Frameworks
Crichton can be used to generate raw responses that can be returned in other application frameworks using the 
[\#to_media_type][] method on objects that implement `Crichton::Representor` or `Crichton::Representor::State`.

```ruby
# some_controller.rb
require 'crichton'

class SomeController
  def media_type_symbol
    # Convert Accept type to Crichton symbol associated with media-type
  end
    
  def show
    drd = DRD.find(params[:id])
    options = # set any context related options
    drd.to_media_type(media_type_symbol, options)
  end
end
```

## Service Objects<a name="service-objects"></a>
Service Objects are a useful concept to keep models separated from logic and access controller methods in generating a
response. For example, a resource descriptor may define a `uri_source` on some protocol implementation of a transition
that it expects on an object. Alternately, one may want to apply some logic to determine conditions from the request
context to pass into a response. 

```ruby
class ServiceObject
  include Crichton::Representor::State
  represents :drds
  
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
    original_to_media_type(options.merge(state: state).merge(other_options))
  end
  
  def state
    # Some logic to determine the state since target will be an array in this example.
  end
  
  private
  def other_options
    # Some logic to get a list of conditions or other options
  end  
end
```

And then, in a controller:

```ruby
class DRDsController
  respond_to(:hale_json, :hal_json, :html)
  
  def index
    drds = ServiceObject.new(DRD.all, self)
    respond_with(drds)
  end
end
```

## Collections
Crichton's opinion is there is no such thing as a "Collection Resource". There are just resources that include data and
transitions. Some resources may actually contain lists of other resources or exist as a series of resources, but 
they are just a resource like any other. 

Thus, what some, using certain "conventions" or ORMs might consider a  "Collection Resource", e.g. an 
`application/json` (non-hypermedia aware media-type) array response are not supported, such as:

```json
[ 
  { "id": 1 },
  { "id": 2 }
]
```

This type of JSON response does not allow setting any attributes or metadata for a resource. Rather, such a resource 
would be returned in a Hypermedia API, for example using `application/hal+json`, as:

```json
{
  "_links": {
    "self": { "href": "..." },
    "items": [ { "href": "..." }, { "href": "..." } ]
  },
  "_embedded": {
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
  },
  "total_count": 2
}
```
or, as `application/json`:

```json
{
  "total_count": 2,
  "items": [ 
    { "id": 1 },
    { "id": 2 }
  ]
}
```

Crichton understands and recursively builds representations of embedded resources as long as each of the associated
objects implements `Crichton::Representor` or `Crichton::Representor::State`. 

### Examples
    
* Using [Service Objects](#service-objects) to wrap an ORM collection, as in the prior example.
* Creating a model

    ```ruby
    class DRDs
      include Crichton::Representor
        
      represents :drds
      
      attr_reader :items
      
      def self.all
        new(DRD.all)
      end
      
      def initialize(items)
        @items = items
      end
        
      def total_count
        items.count
      end
    end
    
    class DRDsController
      respond_to(:hale, :hal, :html, :xhtml)
      
      def index
        drds = DRDs.all
        respond_with(drds)
      end
    end
    ```     

* Wrapping a Hash object with a representor interface using the [\#build_representor][] or the 
[\#build_state_representor][] factory methods.

   ```ruby
   class DRDsController 
     include Crichton::Representor::Factory
     
     def index
       drds = DRD.all
       drds_hash = {
         total_count: drds.count,
         items: drds
       }
       respond_with(build_state_representor(drds_hash, :drds, { state: :collection }))
     end
   end
   ```
   
## Surfing your API in a browser
Crichton supports the media-type `text/html` out of the box so that an API can be surfed in a browser to 
allow fast prototyping of APIs.

### Rails
If a template is defined for a request in Rails, the template is rendered. However, if no template exists and a 
controller is configured to respond to HTML, Crichton will render an HTML version of the resource based on the 
[_API descriptor document_] for the resource.
  
## Supported Media-types<a name="supported-media-types"></a>
The following are currently supported media-types:

* [html - text/html](http://www.ietf.org/rfc/rfc2854)
* [xthml - application/xhtml+xml](http://www.ietf.org/rfc/rfc3236)
* [hal_json - application/hal+json](http://tools.ietf.org/html/draft-kelly-json-hal-06)
* [hale_json - application/vnd.hale+json](https://github.com/mdsol/hale)

## Contributing
See {file:CONTRIBUTING.md} for details.

## Acknowledgements
Thanks to [Mike Amundsen][] and [Jon Moore][] for patient explanations and the whole Hypermedia community that 
helped crystallize ideas underlying Crichton. And, of course, thanks to all the [contributors][].

## Copyright
Copyright (c) 2013 Medidata Solutions Worldwide. See {file:LICENSE.md} for details.

[documentation]: http://rubydoc.info/github/mdsol/crichton
[demo service]: https://github.com/fosrias/crichton-demo-service
[\#to_media_type]: http://rubydoc.info/github/mdsol/crichton/Crichton/Representor/Serialization/MediaType#to_media_type-instance_method
[supported media-types]: #supported-media-types
[Documentation]: http://rubydoc.info/github/mdsol/crichton
[Mike Amundsen]: https://twitter.com/mamund
[Jon Moore]: https://twitter.com/jon_moore
[contributors]: https://github.com/mdsol/crichton/graphs/contributors

[\#build_representor]: http://rubydoc.info/github/mdsol/crichton/Crichton/Representor/Factory#build_representor-instance_method
[\#build_state_representor]: http://rubydoc.info/github/mdsol/crichton/Crichton/Representor/Factory#build_state_representor-instance_method
