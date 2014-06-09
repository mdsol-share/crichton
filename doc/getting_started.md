# @title Getting Started

12-factor support with dice_bag.

Config options

## Logging
If you use Rails, then the `Rails.logger` will be configured automatically. If no logger is configured, the current 
behavior is to log to STDOUT. You can override it by calling `Crichton.logger = Logger.new("some logging sink")`
early on. This only works before the first use of the logger - for performance reasons the logger
object is memoized.

## Middleware

# Home Response

The demo supports "home" entry point requests in various media types. To do this, you must configure rack middleware
in config/application.rb:

```
$ require 'crichton/middleware/resource_home_response'
...
$ # expiry is optional, # of minutes to expire the request response, string or symbol
$ config.middleware.use "Crichton::Middleware::ResourceHomeResponse", {'expiry' => 20}
```

Place one or more resource configuration files in the /api_descriptor folder, then restart the server.

In your browser, you simply call the root of the service: http://localhost:3000

You can also use curl with many media types. The home responder looks at the ACCEPT_HEADER entry in the request
header. With curl, one uses --header 'Accepts: <media_type>'

```
$ curl -v --header "Accept: text/html" localhost:3000
```

The following are acceptable media types and the content type set in the response header

* text/html------------- text/html
* application/xhtml+xml- application/xhtml+xml
* application/xml------- application/xml
* application/json-home- application/json-home
* application/json------ application/json
* asterisk/asterisk----- asterisk/asterisk 

If one sends in nothing or an unsupported media type, the server returns with:

> Not Acceptable media type(s): bad_media_type , supported types are: text/html, application/xhtml+xml, application/xml, application/json-home, application/json, asterisk/asterisk

## Alps Profile  Response

The demo supports "alps profile" requests in various media types. purely from middleware.  To do this, you must configure rack 
middleware in config/application.rb:

```
$ require 'crichton/middleware/alps_profile_response'
...
$ # expiry is optional, # of minutes to expire the request response, string or symbol
$ config.middleware.use "Crichton::Middleware::AlpsProfileResponse", {'expiry' => 20}
```

Place one or more resource configuration files in the /api_descriptor folder, then restart the server.

In your browser, you can call (and verify) the following alps paths:
* http://localhost:3000/alps/DRDs
* http://localhist:3000/alps/DRDs/
* http://localhist:3000/alps/DRDs#list (#list is an example fragment that is seen when you perform a home request of localhost:3000)

You can also use curl with 3 media types. The home responder looks at the ACCEPT_HEADER entry in the request
header. With curl, one uses --header 'Accepts: <media_type>'

```
$ curl -v --header "Accept: text/html" localhost:3000/alps/DRDs
```

The following are acceptable media types and the content type set in the response header

* text/html------------- application/xml
* application/alps+xml-- application/alps+xml
* application/alps+json- application/alps+json

If one sends in nothing or an unsupported media type, the server returns with:

> Not Acceptable media type(s): bad_media_type , supported types are: text/html, application/slps+xml, application/alps+json

If you make a request on a non-existent resource (e.g localhost:3000/alps/blah) the response will be "Profile <ID> not found"





## Overview
To use the serialization functionality, you need to call the serializer. If you are working in Rails, the serializer is 
automatically registered with the Rails MIME-type mechanism. You can also call the serializer manually by calling 
`object.to_media_type(:xhtml, {})`.  In this call the first argument is the media type. Currently, `:xhtml` and `:html` 
are registered, but other media types are expected). The second argument is the options hash.

## Options Hash

The options hash can contain the following values:

- `conditions: [:condition]`
  Conditions are defined in the States section of the descriptor document. See the [Resource Descriptors](resource_descriptors.md) document for more information about conditions.
- `semantics: :styled_microdata`
  The semantics option indicates the semantic mark-up type to apply to the resource. Valid options include: `:microdata` and `:styled_microdata`. 
  If you not include semantics, Crichton defaults to `:microdata`.
- `embed_optional: {'name1' => :embed, 'name2' => :link}`
  The keys need to be strings that correspond to the name of the attribute that has an `embed: single-optional`,
`multiple-optional`,`single-optional-link`, or `multiple-optional-link`.
  The first two embed values - those without `-link` - default to `:embed` when you specify no `embed_optional` parameter. The embed values `-link` default to embedding a link.

## Rails Code Example
A Rails example of serialization appears below.

NOTE: The options hash typically generates elsewhere. For the sake of the example, it appears in the `respond_with` call.

```ruby
  def show
    @drd = Drd.find_by_uuid(params[:id])
    respond_with(@drd, {conditions: :can_do_anything, embed_optional: {'items' => :link})
  end
```

