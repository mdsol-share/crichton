# @title Getting Started

## Configuration
Crichton includes a default [Dice Bag][] template that supports [12-Factor App][] configuration of applications
that implement Crichton. To configure your application, perform the following steps: 

1. Generate the `crichton.yml.dice` template in the `path_to_app\config` (default) folder of your application.

    ```
    [bundle exec] rake config:generate_all
    ```
2. Update the template with local development defaults.
3. Generate the `cricthon.yml` configuration.

    ```
    [bundle exec] rake config:deploy
    ```

It is a best practice to commit your `crichton.yml.dice` template to your repo, not `crichton.yml`, and
to include a startup rake task in your application that generates crichton.yml during the release phase. For more
information, see the [Dice Bag][] documentation.

### Crichton YAML Properties<a name="crichton-yaml-properties"></a>
The following list defines the configuration properties:

* `alps_base_uri` - The base URI for the ALPS profile registry for profiles that are referenced as relative paths in an
[_API Descriptor Document_][]. If none, use `http://[domain]/alps`.
* `deployment_base_uri` - The base URI for the application: `http://[domain]`
* `discovery_base_uri` - The base URI for a discovery service that Crichton will publish entry points to.
* `documentation_base_uri` - The base URI for any hosted external documentation that is referenced as relative paths in an [_API Descriptor Document_][].
* `use_alps_middleware` - Rails only. Identifies whether or not to autoload middleware to support rendering local ALPS profiles.
* `alps_profile_response_expiry` - Configures the expiry of ALPS middleware that serves ALPS profiles directly from
the service.
* `use_discovery_middleware` - Rails only. Identifies whether or not to autoload middleware to support rendering local resource catalog of entry points.
* `resources_catalog_response_expiry` - Configures the expiry of resource entry point middleware that
serves a catalog of resource entry points provided directly from the service.
* `service_level_target_header` - Configures a service level target (SLT) response header name. If left unspecified,
the property defaults to `REQUEST_SLT`.
* `crichton_proxy_base_uri` - URI to use to capture and proxy AJAX requests to related resources when surfing an
API in a browser. Allows an application to proxy the request for authentication/authorization.
* `css_uri` - The fully qualified URI for a CSS file to use when surfing an API in a browser.
* `js_uri` -  The fully qualified URI for a Javascript file to load when surfing an API in a browser.

## Vendor Profile Dependencies
Given that an [_API Descriptor Document_][] may reference external ALPS profiles, it is important to vendor external
profiles into your application. This way, changes to those profiles do not modify application behavior unawares by being dynamically loaded at runtime. Vendored profiles are loaded from the local repository instead of an external
ALPS profile registry.

To support vendoring, Crichton contains two rake tasks: one task to vendor external profiles and another task to check if differences exist between vendored profiles and external profiles. These methods are, respectively:

````
$ rake alps:store_all_external_documents
$ rake alps:check_all_external_documents
````

## Middleware
Crichton includes utility Rack middleware for interacting with Hypermedia APIs in a service. For Rails applications,
this middleware is automatically included. For other frameworks, you can add the middleware to provide this default
functionality.

### Entry Points
Returns a catalog of resource entry points for a service on the root of the service.

In your browser, you simply call the root of the service to access a list of resource entry points. You can also use
curl and content-negotiate responses with several media types.

```
$ curl -v --header "Accept: application/hal+json" http://example.com
```

The following are acceptable media types for content-negotiating the entry points catalog:

* html - text/html
* xhtml - application/xhtml+xml
* xml - application/xml
* hale_json - application/vnd.hale+json
* hal_json - application/hal+json
* json - application/json
* any - \*/\*

If you have not set an `Accept` header or used an unsupported media type, the server returns the following error:

> Status: 406
Not Acceptable media type(s): [bad_media_type]. Supported types are: text/html,
application/xhtml+xml, application/xml, application/vnd.hale+json, application/hal+json, application/json, \*/\*

### ALPS Profiles
Returns either a list of ALPS profiles or individual profiles for service resources.

In your browser, you simply call the `root/alps` path of the service to access a list of resource entry points. You can
also use curl and content-negotiate responses with several media types.

```
$ curl -v --header "Accept: application/alps+xml" http://example.com/alps
```

In your browser, you can call also load any profile links, found in the above list to view the actual individual
profile. For example, you can load `http://example.com/alps/DRDs`. You can also curl individual profiles.

```
$ curl -v --header "Accept: application/alps+xml" http://example.com/alps/DRDs
```

The following are acceptable media types that you can set as the content type in the response header:

* html (text/html, for surfing ALPS Profiles in a browser) - application/xml
* alps_xml - application/alps+xml
* alps_json - application/alps+json

If you have not set an `Accept` header or used an unsupported media type, the server returns the following error:

> Status: 406
Not Acceptable media type(s): [bad_media_type]. Supported types are: text/html,
application/alps+xml, application/alps+json.

If you make a request on a non-existent resource - for example, http://example.com/alps/blah - the error response will be:
	"Profile <ID> not found"

### Non-Rails Frameworks
Include non-Rails frameworks as normal Rack middleware at the top of the stack.

```
require 'crichton/middleware/service_resources_catalog'
require 'crichton/middleware/alps_profile_response'

# ...
# expiry is optional, # of minutes to expire the request response, string or symbol
config.middleware.use "Crichton::Middleware::ServiceResourcesCatalog", { 'expiry' => 20 }

# expiry is optional, # of minutes to expire the request response, string or symbol
config.middleware.use "Crichton::Middleware::AlpsProfileResponse", { 'expiry' => 20 }
```

## Logging
If you use Rails, then the `Rails.logger` is configured automatically. If you have no logger configured, the current
behavior is to log to STDOUT. You can override it by calling the following:

 ```ruby
 Crichton.logger = Logger.new("some logging sink")
 ```

[\#to_media_type]: http://rubydoc.info/github/mdsol/crichton/Crichton/Representor/Serialization/MediaType#to_media_type-instance_method
[Dice Bag]: https://github.com/mdsol/dice_bag
[sample template]: ../lib/crichton/dice_bag/crichton.yml.dice
[12-Factor App]: http://12factor.net
[_API Descriptor Document_]: api_descriptor_documents.md
