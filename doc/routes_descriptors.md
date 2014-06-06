# @title Route Descriptors
# Overview
Route descriptors define metadata that you can use to scaffold models and controllers and to generate routes for
an application that is associated with _Resource Desciptors_ transitions. Route descriptors are OPTIONAL.

## Route Descriptor Properties
Route descriptor properties include the following:
- `routes` - Optional. Indicates the routes descriptor section. 
 - \[alps_id\] - A YAML key that is the unique ID of the associated ALPS profile.
   - \[transition\] - The transition that is implemented and is related to a specific transition descriptor.
     - `controller` - Optional. The name of the associated controller.
      - `action` - Optional. The name of the associated method in the controller.

## Route Descriptor Dependencies
Route Descriptors are directly related to [Data Descriptors](data_descriptors.md) and
[Transition Descriptors](transition_descriptors.md) in a _Resource Descriptor_. Thus, a route descriptor must:

- Have a related Semantic Data Descriptor whose ID - the YAML key - is the same as the YAML keys immediately
following the `routes` key.
- Have related Transition Descriptors whose ID - the YAML key - is the same as the YAML keys immediately
following the `Data Descriptor` keys.

## Code Example
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
- [Back to API Descriptor Document](descriptors_document.md)
- [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
