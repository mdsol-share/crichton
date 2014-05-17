# @title Protocol Descriptors
# Overview
Protocol descriptors define the protocol-specific implementation of the transitions defined semantically for the 
resource(s) in the _API Descriptor Document_. Currently, only the `http` protocol is implemented. You must define protocol descriptors using the "[protocol name]_protocol_" naming convention. For example, 'http_protocol', 'tcp_protocol', and so on.

## Protocol Descriptor Properties
The following bullets highlight the properties of supported protocol descriptors.

### HTTP Properties
HTTP protocol properties include the following:
- \[transition\] - The implemented transition relative to a specific transition descriptor.
   - `uri` - Required. The URI of an endpoint. If templated, the object being represented must contain an attribute with the templated parameter(s).
   - `method` - Required. The uniform interface method; for example, GET, POST, or DELETE.
   - `headers` - Optional. An array of headers to be set on responses.
   - `slt` - Optional. The Service Level Target (SLT) for the endpoint.
      - `99th_percentile` - Required if there is an SLT. The 99th percentile time-limit.
      - `std_dev` - Required if there is an SLT. The standard deviation around the 99th percentile.
      - `requests_per_second` - Required if there is an SLT. The load the SLT is valid at.

## Protocol Descriptor Dependencies
Route descriptors are directly related to [Transition Descriptors](transition_descriptors.md) in a 
_Resource Descriptor_. Thus a protocol descriptor must:
- Correspond to a supported protocol.
- Correspond to transition descriptors associated with a resource profile in the _Resource Descriptor_.

## Code Example
The following example highlights a few parts of the [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml) `descriptors` section. Some material is removed for simplicity. 

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

## Related Topics
- [Back to API Descriptor Document](descriptors_document.md)
- [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
