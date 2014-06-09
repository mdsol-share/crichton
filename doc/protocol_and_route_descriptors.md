# @title Protocol and Routes Descriptors

## Overview

## Protocol Descriptors
Protocol descriptors define the protocol-specific implementation of the transitions defined semantically for the 
resource(s) in the _API Descriptor Document_. Currently, only the `http` protocol is implemented. You must define protocol descriptors using the "[protocol name]_protocol_" naming convention. For example, 'http_protocol', 'tcp_protocol', and so on.

### Properties
The following bullets highlight the properties of supported protocol descriptors.

#### HTTP Properties
HTTP protocol properties include the following:
- \[transition\] - The implemented transition relative to a specific transition descriptor.
   - `uri` - Required. The URI of an endpoint. If templated, the object being represented must contain an attribute with the templated parameter(s).
   - `method` - Required. The uniform interface method; for example, GET, POST, or DELETE.
   - `headers` - Optional. An array of headers to be set on responses.
   - `slt` - Optional. The Service Level Target (SLT) for the endpoint.
      - `99th_percentile` - Required if there is an SLT. The 99th percentile time-limit.
      - `std_dev` - Required if there is an SLT. The standard deviation around the 99th percentile.
      - `requests_per_second` - Required if there is an SLT. The load the SLT is valid at.

### Dependencies
Route descriptors are directly related to [Transition Descriptors](transition_descriptors.md) in a 
_Resource Descriptor_. Thus a protocol descriptor must:
- Correspond to a supported protocol.
- Correspond to transition descriptors associated with a resource profile in the _Resource Descriptor_.

### Code Example
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

## Route Descriptors 
Route descriptors define metadata that you can use to scaffold models and controllers and to generate routes for
an application that is associated with _Resource Desciptors_ transitions. Route descriptors are OPTIONAL.

### Properties
Route descriptor properties include the following:
- `routes` - Optional. Indicates the routes descriptor section. 
 - \[alps_id\] - A YAML key that is the unique ID of the associated ALPS profile.
   - \[transition\] - The transition that is implemented and is related to a specific transition descriptor.
     - `controller` - Optional. The name of the associated controller.
      - `action` - Optional. The name of the associated method in the controller.

### Dependencies
Route Descriptors are directly related to [Data Descriptors](data_descriptors.md) and
[Transition Descriptors](transition_descriptors.md) in a _Resource Descriptor_. Thus, a route descriptor must:

- Have a related Semantic Data Descriptor whose ID - the YAML key - is the same as the YAML keys immediately
following the `routes` key.
- Have related Transition Descriptors whose ID - the YAML key - is the same as the YAML keys immediately
following the `Data Descriptor` keys.

### Code Example
The following example highlights a few parts of the [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml) `routes` section. In-line comments
are expounded in the structure and some material is removed for simplicity (indicated by # ...). 

```yaml
routes:
  drds: # Corresponds to fragment ID of related secondary profile descriptor of the resource.
    list: &list # Corresponds to the 'list' transition of the 'drds' resource.
      controller: drds_controller
      action: index
    search: *list # Corresponds to the 'search' transition of the 'drds' resource.
    create: # Corresponds to the 'create' transition of the 'drds' resource.
      controller: drds_controller
      action: create
```

## Related Topics
- [Back to API Descriptor Document](api_descriptor_documents)
- [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
