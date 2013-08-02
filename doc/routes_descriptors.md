# @title Route Descriptors
# Route Descriptors.
Route descriptors define the metadata that can be used to scaffold models and controllers and generate routes for
an application associated with a _Resource Desciptors_ transitions. These are OPTIONAL descriptors.

## Properties
* `routes` - Indicates routes descriptor section. OPTIONAL. 
  * \[alps_id\] - A YAML key that is the unique ID of the associated ALPS profile.
    * \[transition\] - The implemented transition related to a specific transition descriptor.
        * `controller` - The name of the associated controller: OPTIONAL.
        * `action` - The name of the associated method in the controller. OPTIONAL.

## Example
The following example highlights a few parts of the [Example Resource Descriptor][] `routes` section. In-line comments
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

## Descriptor Dependencies
Route Descriptors are directly related to [Data Descriptors](data_descriptors.md) and
[Transition Descriptors](transition_descriptors.md) in a _Resource Descriptor_. Thus, a route descriptor:

* MUST have a related Semantic Data Descriptor whose ID (YAML key) is the same as the YAML keys immediately
following the `routes` key.
* MUST have related Transition Descriptors whose ID (YAML key) is the same as the YAML keys immediately
following the Data Descriptor keys.

[Back to Resource Descriptors](resource_descriptors.md)
[Example Resource Descriptor]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
