# @title Getting Started

## Resource Design
Crichton's opinion (along with many others) is that a well-defined Hypermedia API exposes a state-machine interface
that maximizes "shared understanding" of the elements in the underlying resources. Assuming one has done this design, 
there are a number of artifacts that one can develop to simplify implementing hypermedia. The following outlines the 
process and artifacts of an (overly simplified) eBook API example that illustrates underlying concepts used to create an
[_API Descriptor Document_][] for the related resources.

### Analyze Resource Semantics
Assuming one has analysed a business problem and isolated a resource or simple set of related resources including 
determining desired properties and actions necessary to accomplish the associated work, the next step is groom the 
resource(s). This analysis is part of "Contract First" development and lays the groundwork for Hypermedia Contracts and 
State-machine analysis and definition.

Resource definition is about the best names and related meaning (semantics, or vocabulary) of the data properties and 
link relations of a resource  vs. a schema per se. Ideally, groomed resources and associated profiles that result from 
this analysis would represent the generally understandable, reusable and optimum interface for the work associated with 
the resource, such that it could be published in public profile registries with that confidence.

The [Sample eBooks Hypermedia Contract][] summarizes a proposed format for this analysis.

### Determine Resource State-machines
Hypermedia APIs implement the Hypermedia constraint of the REST architecture style known as "hypermedia as the engine 
of application state", or HATEOAS. Implicit in this statement is the fact that Hypermedia APIs expose state-machine 
resources, that is data and available state transitions at runtime.

[Example eBooks State-machine Analysis][]

### Putting it all together
Given 

## Configuration
Crichton includes a default [Dice Bag][] template that supports [12-Factor App][] configuration of applications 
implementing Crichton. To configure configure your application:

* Generate the `crichton.yml.dice` template in the `path_to_app\config` (default) folder of your application

    ```
    [bundle exec] rake config:generate_all
    ```
* Update the template with local development defaults
* Generate the `cricthon.yml` configuration
    
    ```
    [bundle exec] rake config:deploy
    ```

It is considered a best practice to commit your `crichton.yml.dice` template to your repo (not `crichton.yml`) and 
include a startup rake task in your application that generates crichton.yml during the release phase. For more 
information, see the [sample template][] and [Dice Bag][] documentation.

### Crichton YAML Properties
The following defines the configuration properties:

* `alps_base_uri` - The base URI for the ALPS profile registry for profiles referenced as relative paths in an 
[_API Descriptor Document_][]. If none, use the `http://[domain]/alps`. 
* `deployment_base_uri` - The base URI for the application: `http://[domain]`
* `discovery_base_uri` - The base URI for a discovery service that Crichton will publish entry points to.
* `documentation_base_uri` - The base URI for any hosted external documentation referenced as relative paths in an
[_API Descriptor Document_][].
* `alps_profile_response_expiry` - Configures the expiry of ALPS middleware that serves ALPS profiles directly from
the service.
* `resource_home_response_expiry` - Configures the expiry of resource entry point middleware that serves a catalogue of
 resource entry points served directly from the service. 
* `crichton_proxy_base_uri` - URI to use to capture and proxy AJAX requests to related resources when surfing an 
API in browser. Allows an application to proxy the request for authentication/authorization.
* `css_uri` - The fully-qualified URI for a CSS file to use when surfing an API in a browser. 
* `js_uri` -  The fully-qualified URI for a Javascript file to load when surfing an API in a browser.
  
## Vendor Profile Dependencies
Given that an [_API Descriptor Document_][] may reference external ALPS profiles, it is important to vendor external
profiles into your application so that changes to those profiles do not modify application behavior unawares by being
dynamically loaded at runtime. Vendored profiles are loaded from the local repository instead of an external 
ALPS profile registry.

To support this, Crichton contains two rake tasks, one to vendor external profiles and another to check if differences
exist between vendored profiles and external profiles. These methods are, respectively:

````
$ rake store_all_external_documents
$ rake check_all_external_documents
````

## Middleware
Crichton includes utility Rack middleware for interacting with Hypermedia APIs in a service. For Rails applications, 
this middleware is automatically included. For other frameworks, the middleware can be added to provide this default 
functionality.

### Entry Points
Returns a catalogue of resource entry points for a service on the root of the service.

In your browser, you simply call the root of the service to access a list of resource entry points. You can also use 
curl and content negotiate responses with several media types. 

```
$ curl -v --header "Accept: application/json-home" http://example.com
```

The following are acceptable media types for content negotiating the entry points catalogue:

* html - text/html
* xhtml - application/xhtml+xml
* xml - application/xml
* json - home - application/json-home
* json - application/json
* any - \*/\*

If no `Accept` header is set or an unsupported media type is used, the server returns:

> Status: 406
Not Acceptable media type(s): [bad_media_type]. Supported types are: text/html, 
application/xhtml+xml, application/xml, application/json-home, application/json, \*/\*

### ALPS Profiles
Returns either a list of ALPS profiles, or individual profiles for service resources. 

In your browser, you simply call the `root/alps` path of the service to access a list of resource entry points. You can 
also use curl and content negotiate responses with several media types. 

```
$ curl -v --header "Accept: application/alps+xml" http://example.com/alps
```

In your browser, you can call also load any profile links, found in the above list to view the actual individual
profile, e.g. `http://example.com/alps/DRDs`. You can also curl individual profiles as well.

```
$ curl -v --header "Accept: application/alps+xml" http://example.com/alps/DRDs
```

The following are acceptable media types and the content type set in the response header

* html - application/xml 
* alps_xml - application/alps+xml
* alps_json - application/alps+json


If no `Accept` header is set or an unsupported media type is used, the server returns:

> Status: 406
Not Acceptable media type(s): [bad_media_type]. Supported types are: text/html, 
application/alps+xml, application/alps+json.

If you make a request on a non-existent resource (e.g., http://example.com/alps/blah) the response will be: 
"Profile <ID> not found"

### Non-Rails Frameworks
Just include as normal Rack middleware at the top of the stack.

```
require 'crichton/middleware/resource_home_response'
require 'crichton/middleware/alps_profile_response'

# ...
# expiry is optional, # of minutes to expire the request response, string or symbol
config.middleware.use "Crichton::Middleware::ResourceHomeResponse", { 'expiry' => 20 }

# expiry is optional, # of minutes to expire the request response, string or symbol
config.middleware.use "Crichton::Middleware::AlpsProfileResponse", { 'expiry' => 20 }
```

## Logging
If you use Rails, then the `Rails.logger` will be configured automatically. If no logger is configured, the current 
behavior is to log to STDOUT. You can override it by calling:
 
 ```ruby
 Crichton.logger = Logger.new("some logging sink")
 ```

[\#to_media_type]: http://rubydoc.info/github/mdsol/crichton/Crichton/Representor/Serialization/MediaType#to_media_type-instance_method
[Dice Bag]: https://github.com/mdsol/dice_bag
[sample template]: ../lib/crichton/dice_bag/crichton.yml.dice
[12-Factor App]: http://12factor.net
[_API Descriptor Document_]: api_descriptor_documents.md
[Sample eBooks Hypermedia Contract]: sample_ebooks_hypermedia_contract.md
[Sample eBooks State-machine Analysis]: sample_ebooks_state_machine_analysis.md
[Sample eBooks API Descriptor Document]: sample_ebooks_api_descriptor_document.md
