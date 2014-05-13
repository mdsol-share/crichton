# @title Transition Descriptors
# Overview
Transition descriptors define the semantic descriptions of the state transformation affordances in the profile.
There are 3 different types of transitions: `safe`, `unsafe` and `idempotent` transitions. Transitions can be grouped
by their type under corresponding top-level element.

## Properties
* `transition_type` - Section that groups transition descriptors by type: REQUIRED.
  * \[alps_id\] - A YAML key that is the unique ID of the associated ALPS profile.
    * `doc` - The description of the transition descriptor: REQUIRED.
    * `name` - The name associated with the related element in a response. Overrides the ID of the descriptor as the
    default name: OPTIONAL.
    * `links` - Links related to the transition descriptor: RECOMMENDED.
    * `href` - An underlying ALPS profile: OPTIONAL.
    * `rt` - The return type, as an absolute or relative URI to an ALPS profile: REQUIRED.

## Example
The following example highlights a few parts of the [Example API Descriptor Document][] Sections associated
with transition descriptors and any related data descriptors. In-line comments are expounded in the structure and some 
material is removed for simplicity (indicated by # ...). 

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

## Descriptor Dependencies
Transition descriptors are directly related to [Protocol Descriptors](protocol_descriptors.md) and states section of 
[Resource Descriptors](resource_descriptors.md#states), which indicate implementation details of the transtions. Thus, a 
transition descriptor transition:

* MUST have a related Protocol Descriptor whose ID (YAML key) is the same as some transition.
* MAY use a `name` property to override the associated name of the affordance as implemented in a particular 
media-type.
* SHOULD use a `name` property to override the associated name of the affordance as implemented in a particular 
media-type if the ID of the descriptor is not the required semantic of the descriptor, and is rather a uniqueified ID.
* MUST have a related transition in a State Descriptor for the associated resource.

[Back to API Descriptor Document](descriptors_document.md)
[Example API Descriptor Document]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
