```yaml
id: errors
version: v1.0.0
links:
  profile: errors
  help: Errors
data:
  remedy_description:
    doc: If a remedy is known, describe the remedy here.  If the remedy involves going to another resource, the link to that resource should be described in the remedy link.
    href: http://alps.io/schema.org/Text
  title:
    doc: The error name - a human-readable message related to the current error which may be displayed to the user of the api.
    href: http://alps.io/schema.org/Text
  details:
    doc: Specific information about what triggered the error state.
    href: http://alps.io/schema.org/Text
  logref:
    doc: A unique ID for logging.
    href: http://alps.io/schema.org/Text
  retry-after:
    href: http://alps.io/schema.org/Integer
    doc: Specifies how long in seconds the client should wait before trying the request again.
  httpstatus
    href: http://alps.io/schema.org/Integer
    doc: HTTP status. Either the one returned if it was an HTTP request.
  errorcode:
    href: http://alps.io/schema.org/Text
    doc: Error Code used by this service.
safe:
  profile:
    href: http://alps.io/iana/relations.xml#profile
    doc: The Document describing the properties of an error
    rt: errors
  help:
    href: http://alps.io/iana/relations.xml#help
    doc: Links to a document that describes the error. This has the same definition as the help link relation in the HTML5 specification.
  describes:
    href: http://alps.io/iana/relations.xml#describes
    doc: Link to the resource the error is describing.  If the current resource is not the same as the one the client requested, this should refer the the requested URL.
  monitor:
    href: http://alps.io/iana/relations.xml#monitor
    doc: A log or other resource to track the error.
  error_codes:
    href: http://alps.io/iana/relations.xml#error_codes
    doc: A document outlining the error codes.
idempotent:
  self:
    href: http://alps.io/iana/relations.xml#profile
    doc: The current resource.
  remedy:
    href: http://alps.io/iana/relations.xml#profile
    doc: If the service knows what resource to refer to in order to remedy the situation, this link should point to that resource.
unsafe:
  contact:
    href: http://alps.io/schema.org/Person.xml
    doc: A person to contact to follow up on this error.
```
