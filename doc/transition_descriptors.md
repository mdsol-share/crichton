# @title Transition Descriptors
# Overview
Transition descriptors define the semantic descriptions of the state transformation affordances in the profile.
The presence of a nested data semantic descriptor section indicates the endpoint will involve templating a response, 
either as query parameters, or as a body, depending on the type of the transition. The YAML keys directly under the 
`descriptors` property are the ID properties of the individual descriptors.

## Properties
* `descriptors` - Recursive section that groups transition descriptors or nested semantic descriptors: REQUIRED.
* `doc` - The description of the transition descriptor: REQUIRED.
* `type` - The type of transition, either `safe`, `unsafe` or `idempotent` type: REQUIRED.
* `name` - The name associated with the related element in a response. Overrides the ID of the descriptor as the
default name: OPTIONAL.
* `links` - Links related to the transition descriptor: RECOMMENDED.
* `href` - An underlying ALPS profile: OPTIONAL.
* `rt` - The return type, as an absolute or relative URI to an ALPS profile: REQUIRED.

### Template Properties
The following properties are only used with semantic descriptors representing templates (forms).

* `field_type` - Defines the type of field for the form. Valid values are `input`, `boolean`, `select`, or 
`multi-select`: REQUIRED.
* `enum` - Defines the options for select field types or references another profile associated with the enum: OPTIONAL.
* `validators` - An array of validator objects associated with a field: OPTIONAL.

## Example
The following example highlights a few parts of the [Example Resource Descriptor][] `descriptors` section associated
with transition descriptors and any related data descriptors. In-line comments are expounded in the structure and some 
material is removed for simplicity (indicated by # ...). 

Given that transitions have unique IDs relative to the same block of transitions, it may be necessary to define
transitions in the context of a semantic descriptor. This would only happen if for some reason, two different resources
in a profile had the same transition name pointing to different endpoints. Ideally, profiles should be designed to
avoid this situation.

```yaml
descriptors:
  drds:
    doc: 
      html: <p>A list of DRDs.</p>
    type: semantic
    links:
      self: alps_base/DRDs#drds
    descriptors:
      # Semantics
      # ...
      # Transitions
      # ...
      create:
        doc: Creates a DRD.
        type: unsafe
        rt: drd
        descriptors:# Descriptors associated with a form to template a body associated with the 'create' affordance.
          create-drd: # Unique ID that does not collide with 'create' transition descriptor above.
            type: semantic
            href: update-drd # Relative URI indicates that this should dereference update-drd to include it's semantics.
            links:
              self: alps_base/DRDs#create-drd
              help: documentation_base/Forms/create-drd
            descriptors:
              form-name: # Unique ID that does not collide with 'name' descriptor.
                name: name # Name associated with the associated element in a hypermedia response.
                doc: The name of the DRD.
                type: semantic
                href: http://alps.io/schema.org/Text
                field_type: input
                validators:
                  - presence
              form-leviathan_uuid: # Unique ID that does not collide with 'leviathan_uuid' descriptor.
                name: leviathan_uuid # Name associated with the associated element in a hypermedia response.
                doc: The UUID of the creator Leviathan.
                type: semantic
                href: http://alps.io/schema.org/Text
                field_type: select
                enum:
                  href: http://alps.io.example.org/Leviathans#list 
                validators:
                  - presence  
```

## Descriptor Dependencies
Transition descriptors are directly related to [Protocol Descriptors](transition_descriptors.md) and 
[State Descriptors](data_descriptors.md), which indicate implementation details of the transtions. Thus, a 
transition descriptor transition:

* MUST have a related Protocol Descriptor whose ID (YAML key) is the same as some transition.
* MAY use a `name` property to override the associated name of the affordance as implemented in a particular 
media-type.
* SHOULD use a `name` property to override the associated name of the affordance as implemented in a particular 
media-type if the ID of the descriptor is not the required semantic of the descriptor, and is rather a uniqueified ID.
* MUST have a related transition in a State Descriptor for the associated resource.

[Back to Resource Descriptors](resource_descriptors.md)
[Example Resource Descriptor]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
