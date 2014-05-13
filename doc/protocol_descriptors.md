# @title Protocol Descriptors
# Overview
Protocol descriptors define the protocol specific implementation of the transitions defined semantically for the 
resource(s) in the _API Descriptor Document_. Currently, only `http` is implemented. Protocol descriptors MUST be
defined using "[protocol name]_protocol" naming convention. For example, 'http_protocol', 'tcp_protocol', etc.

## Properties
The following highlight the properties of supported protocol descriptors.

### HTTP Properties
The following properties apply to HTTP protocol definitions.
* \[transition\] - The implemented transition related to a specific transition descriptor.
    * `uri` - The URI of the endpoint. If templated, the object being represented must contain an attribute with the
    templated parameter(s): REQUIRED.
    * `method` - The uniform interface method: REQUIRED.
    * `headers` - An array of headers to be set on responses: OPTIONAL.
    * `slt` - The Service Level Target (SLT) for the endpoint: OPTIONAL.
        * `99th_percentile` - The 99th percentile time limit: REQUIRED if slt.
        * `std_dev` - The standard deviation around the 99th percentile: REQUIRED if slt.
        * `requests_per_second` - The load the SLT is valid at: REQUIRED if slt.

## Example
The following example highlights a few parts of the [Example Resource Descriptor][] `descriptors` section. In-line 
comments are expounded in the structure and some material is removed for simplicity (indicated by # ...). 

```yaml
http_protocol:
  list:
    uri: drds
    method: GET
    headers:
      - Content-Type
      - ETag
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

[Back to API Descriptor Document](descriptors_document.md)
[Example API Descriptor Document]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
