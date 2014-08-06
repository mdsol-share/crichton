# @title Handling Errors

## Simple Setup
Crichton provides default error functionality through a rails generator.  In this case you can simply run
"bundle exec rails generate crichton:errors_description ./lib/". It also optionally takes a resource name as a second
argument if you don't like the default of "Errors", and an api directory as a third argument if you have your
descriptors somewhere other than 'api_descriptors'.

## Using Errors
To use errors, simply instantiate your errors class with the attributes you want and render them in your controller.

```ruby
  require 'crichton_error'
 
  errors = Crichton_error.new({
        title: e.message,
        details: '',
        error_code: error_cause,
        http_status: 422,
        stack_trace: '',
        controller: self
  })

  respond_to do |format|
    format.html { render text: errors.to_media_type(:xhtml, { semantics: :styled_microdata }), status: error_cause }
    format.hale_json { render text: errors.to_media_type(:hale_json), status: error_cause }
  end 
```

## Customizing
To customize Error handling, you can simply extend the functionality generated, or create your own class and
 descriptor file to generate the Errors resource.  For example, if we wanted to add a remedy link we may extend the
 default functionality like so:
 
 ### Custom Errors Descriptor
 ```yaml
 id: Errors
 
 doc: Describes the semantics, states and state transitions associated with Errors.
 
 links:
   self: Errors
   help: Errors/help
 
 semantics:
   title:
     doc: Title SHOULD describe the error in a concise, generic manner.
     href: http://alps.io/schema.org/Text
   details:
     doc: Error explanation and reason for the error.
     href: http://alps.io/schema.org/Text
   error_code:
     doc: Error code is the service's internal error code that describes the error.
     href: http://example.org/profiles/ErrorCodes
   http_status:
     doc: HTTP status is the HTTP status returned, if the service returned one.
     href: http://alps.io/schema.org/Integer
   retry_after:
     doc: This semantic element specifies to the client how long to wait before making another request.
     href: http://alps.io/schema.org/Integer
   logref:
     doc: It is a unique ID used for logging or otherwise tracking the error.
     href: http://alps.io/schema.org/Text
   stack_trace:
     doc: Error stacktrace.
     href: http://alps.io/schema.org/Text
   help:
     doc: The link directs the user to a document that describes the error.
     href: http://alps.io/schema.org/URL
   contact:
     doc: Contact link should provide a contact.
     href: http://alps.io/schema.org/Text
 
 safe:
   try_different_search_term:
     name: remedy
     doc: Try different search term
     href: DRDs#search
   describes_link:
     name: describes
     doc: The link to the resource that the error describes.
 
 resources:
   error:
     doc: Describes an error.
     links:
       self: Errors#error
       help: Errors/help
     descriptors:
       - href: title
       - href: details
       - href: error_code
       - href: http_status
       - href: retry_after
       - href: logref
       - href: stack_trace
       - href: describes_link
       - href: try_different_search_term
     states:
       default:
         transitions:
           describes_link:
             name: describes
             next:
               - location: exit
           help_link:
             name: help
             next:
               - default
           try_different_search_term:
             next:
               - location: DRDs#drds
 
 http_protocol:
   describes_link:
     uri_source: describes_url
   help_link:
     uri_source: help_url
   try_different_search_term:
     uri: drds
     method: GET
     headers:
     slt: &slt2
       99th_percentile: 250ms
       std_dev: 50ms
       requests_per_second: 25
 ```
 
 ### Custom Errors Class
 ```ruby
 class Error
   include Crichton::Representor::State
   represents :error
   attr_reader :title, :details, :error_code, :http_status, :stack_trace, :controller
 
   def initialize(data = {})
     data.each { |name, value| instance_variable_set("@#{name.to_sym}", value) }
   end
 
   def describes_url
     controller.request.path
   end
 end
 ```

 
