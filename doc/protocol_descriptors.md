# @title Protocol Descriptors
# Overview
Protocl descriptors define the protocol specific implementation of the transitions defined semantically for the 
resource(s) in the a _Resource Descriptor_. Currently, only `http` is implemented. 

## Properties
The following highlight the properties of supported protocol descriptors.

### HTTP Properties
The following properties apply to HTTP protocol definitions.

* `uri` - The URI of the endpoint. If templated, the object being represented must contain an attribute with the
templated parameter(s): REQUIRED.
* `entry_point` - If `true` indicates a resource entry point: OPTIONAL.
* `method` - The uniform interface method: REQUIRED.
* `content_types` - An array of media-types that are returned as representations of the resource. Used to populate the 
type attribute in links as hints to the available media-types: OPTIONAL.
* `headers` - An array of headers to be set on responses: OPTIONAL.
* `status_codes` - The status codes that may be returned by this endpoint and what they mean: OPTIONAL.
    * `description` - The description of the status code: OPTIONAL.
    * `notes` - An array of notes to include in human-readable documentation: OPTIONAL.
* `slt` - The Service Level Target (SLT) for the endpoint: OPTIONAL.
    * `99th_percentile` - The 99th percentile time limit: REQUIRED if slt.
    * `std_dev` - The standard deviation around the 99th percentile: REQUIRED if slt.
    * `requests_per_second` - The load the SLT is valid at: REQUIRED if slt.

## Example
The following example highlights a few parts of the [Example Resource Descriptor][] `descriptors` section. In-line 
comments are expounded in the structure and some material is removed for simplicity (indicated by # ...). 

```yaml
protocols:
  http:
    list:
      uri: drds
      entry_point: drds # Indicates this endpoint is a resource entry point for the protocol.
      method: GET
      content_types:
        - application/json
        - application/hal+json
        - application/xhtml+xml
      headers:
        - Content-Type
        - ETag
      status_codes:
        200:
          description: OK
          notes:
            - We have processed your request and returned the data you asked for.
      slt: &slt1
        99th_percentile: 100ms
        std_dev: 25ms
        requests_per_second: 50 
```

## Descriptor Dependencies
Route Descriptors are directly related to [Transition Descriptors](transition_descriptors.md) in a 
_Resource Descriptor_. Thus a protocol descriptor:

* MUST correspond to a supported protocol (currently only HTTP).
* MUST correspond to transition descriptor associated with a resource profile in the _Resource Descriptor_.

[Back to Resource Descriptors](resource_descriptors.md)
[Example Resource Descriptor]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
