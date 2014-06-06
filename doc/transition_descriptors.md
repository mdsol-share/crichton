# @title Transition Descriptors
# Overview
Transition descriptors define the semantics of the state transformation affordances in the profile. There are three types of transitions: `safe`, `unsafe`, and `idempotent`. You can group transitions by their type under the corresponding top-level element.

## Transition Descriptor Properties
- `transition_type` - Required. Section that groups transition descriptors by type.
 - \[alps_id\] - A YAML key that is the unique ID of the associated ALPS profile.
   - `doc` - Required. A human-readable description of the transition descriptor.
    - `name` - Optional. The name associated with the related element in a response. Overrides the ID of the descriptor as the default name.
    - `links` - Recommended. Links related to the transition descriptor.
    - `href` - Optional. An underlying ALPS profile.
    - `rt` - Required. The return type; enter as an absolute or relative URI to an ALPS profile.

## Transition Descriptor Dependencies
Transition descriptors relate directly to elements in the [Protocol Descriptors](protocol_descriptors.md) and to the states section of [Resource Descriptors](resource_descriptors.md#states). These sections indicate implementation details of the transtions. Thus, dependencies for a transition descriptor include the following:

- Must have a related Protocol Descriptor whose ID - the YAML key - is the same as some transition.
- Must use a `name` property to override the associated name of the affordance as implemented in a specific media-type.
- SHOULD use a `name` property to override the associated name of the affordance as implemented in a particular 
media-type if the ID of the descriptor is not the required semantic of the descriptor, and is rather a uniqueified ID.
- Must have a related transition in a State Descriptor for the associated resource.

## Code Example
The following example highlights a few parts of the [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml) sections associated with transition descriptors and any related data descriptors. In-line comments are expounded in the structure and some material is removed for simplicity, indicated by # ... . 

```yaml
safe:
  list:
    doc: Returns a list of DRDs.
    name: self
    rt: drds
  search:
    doc: Returns a list of DRDs that satisfy the search term.
    rt: drds
    parameters:
      - href: name
        ext: _name
      - href: term
        field_type: text

idempotent:
  activate:
    doc: Activates a DRD if it is deactivated.
    rt: drd
  deactivate:
    doc: Deactivates a DRD if it is activated.
    rt: drd

unsafe:
  create:
    doc: Creates a DRD.
    rt: drd
    links:
      profile: DRDs#create
      help: Forms/create
    href: update
    parameters:
      - href: name
        ext: _create_name
      - href: leviathan_uuid
        field_type: text
      - href: leviathan_health_points
        field_type: number
        validators:
          - required
          - min: 0
          - max: 100
        sample: 42
      - href: leviathan_email
        field_type: email
        validators:
          - required
          - pattern: "^.+@.+$"
```

## Related Topics
- [Back to API Descriptor Document](descriptors_document.md)
- [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
