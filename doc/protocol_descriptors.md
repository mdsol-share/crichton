# @title Protocol Descriptors
# Overview
Defines the protocol specific implementation of the transitions defined semantically for the resource(s) in the 
profile. Currently, only `http` is implemented. Each transitions must be defined in a protocol section, although 
they may be implemented in different protocols.

* `slt` - The Service Level Target (SLT) for the endpoint: OPTIONAL.

### HTTP Properties
The following properties apply to HTTP protocol definitions.

* `uri` - The URI of the endpoint. If templated, the object being represented must contain an attribute with the
templated parameter(s): REQUIRED.
* `entry_point` - If `true` indicates a resource entry point: OPTIONAL.
* `method` - The uniform interface method: REQUIRED.
* `content_types` - The media-types that are returned as representations of the resource. Used to populate the type
attribute in links as hints to the available media-types: OPTIONAL.
* `headers` - Any headers to be set on responses: OPTIONAL.
* `status_codes` - The status codes that may be returned by this endpoint and what they mean: OPTIONAL.
