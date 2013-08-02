# @title Data Descriptors
# Overview
Data Descriptors define the semantics, or vocabulary, of the data-related attributes of a resource and/or the semantics 
of the data associated with 'forms' in transitions that either template queries for a `safe` transition or template 
bodies in `unsafe` and `idempotent` transitions.

## Properties
The YAML keys directly under the `descriptors` property are the ALPS IDs of the individual descriptors and thus must be
unique within the document. The `name` property can be used to specify the semantic name that will be used in a
response. Otherwise, the ID will be the name of the associated attribute in the representation of the resource.

* `descriptors` - Recursive section that groups semantic and transition descriptors.
  * \[alps_id\] - A YAML key that is the unique ID of the associated ALPS profile.
    * `doc` - The description of the semantic descriptor: REQUIRED.
    * `name` - The name associated with the related element in a response. Overrides the ID of the descriptor as the
default name: OPTIONAL.
    * `type` - The type of the descriptor. For data related descriptors, only use `semantic`: REQUIRED.
    * `links` - Links related to the semantic descriptor: RECOMMENDED. Minimally, should include a `self` link that 
indicates the URI of the descriptor for top-level descriptors.
    * `href` - The underlying ALPS profile, either representing another resource or a primitive profile. See 
[Primitive Profiles](primitive_profiles.md) for more information: REQUIRED.
    * `sample` - A sample data value for use in generating sample representations by media-type: RECOMMENDED.
    * `embed` - Indicates that this resource should be embedded in a response. Valid values are `single`, `multiple`, 
and `optional`. The default, if not specified, is `single`. The value `multiple` indicates the item should be embedded 
as an array. The value `optional` indicates this property should only be included is specifically requested using an 
associated transition that specifies its optional inclusion: OPTIONAL.

### Template Properties
The following properties are only used with semantic descriptors representing templates (media-type form, 
in contrast to a link).

* `field_type` - Defines the type of field for the form. Valid values are `input`, `boolean`, `select`, or 
`multi-select`: REQUIRED.
* `enum` - Defines the options for select field types or references another profile associated with the enum: OPTIONAL.
* `validators` - An array of validator objects associated with a field: OPTIONAL.

## Examples
The following example highlights a few parts of the [Example Resource Descriptor][] `descriptors` section associated
with data descriptors and template descriptors. In-line commentsare expounded in the structure and some material is 
removed for simplicity (indicated by # ...). 

```yaml
descriptors:
  drds: # Defines a top-level descriptor of a resource.
    doc: 
      html: <p>A list of DRDs.</p>
    type: semantic
    links:
      self: alps_base/DRDs#drds
    descriptors: # Defines descriptors of a 'drds' resource.
      # Semantics
      total_count: # Descriptor associated with a 'total_count' attribute in a resource response.
        doc: The total count of DRDs.
        type: semantic
        href: http://alps.io/schema.org/Integer # Primitive profile of the resource.
        sample: 1
      items: # Descriptor associated with a 'items' attribute in a resource response.
        doc: An array of embedded DRD resources.
        type: semantic
        href: Array
        embed: multiple # Select non-ALPS values are treated as extensions in the profile.
      # Transitions
      # ...
      create:
        doc: Creates a DRD.
        type: unsafe # Indicates a transition descriptor. Here to highlight data semantics of the related form.
        rt: drd
        descriptors: # Descriptors associated with a form to template a body associated with the 'create' affordance.
          create-drd: # Unique ID that does not collide with 'update' transition descriptor above.
            type: semantic
            href: update-drd # Indicates that this should de-reference update-drd
            links:
              self: alps_base/DRDs#drd/create/create-drd
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
  drd:
    doc: |
      Diagnostic Repair Drones or DRDs are small robots that move around Leviathans. They are
      built by a Leviathan as it grows.
    type: semantic
    links:
      self: alps_base/DRDs#drd
    descriptors:
      # Semantics
      uuid:
        doc: The UUID of the DRD.
        type: semantic
        href: http://alps.io/schema.org/Text
        sample: 007d8e12-babd-4f2c-b01e-8b5e2f749e1b           
      name:
        doc: The name of the DRD.
        type: semantic
        href: http://alps.io/schema.org/Text
        sample: 1812
      status:
        doc: How is the DRD.
        type: semantic
        href: http://alps.io/schema.org/Text
        sample: renegade
      kind:
        doc: What kind is it.
        type: semantic
        href: http://alps.io/schema.org/Text
        sample: standard
      # ...
      # Transitions
      # ...
      update:
        doc: Updates a DRD.
        type: idempotent
        descriptors:  # Descriptors associated with a form to template a body associated with the 'update' affordance.
          update-drd: # Unique ID that does not collide with 'update' transition descriptor above.
            type: semantic
            links:
              self: alps_base/DRDs#update-drd  
              help: documentation_base/Forms/update-drd
            descriptors:
              form-status: # Unique value to differentiate from 'status' descriptor.
                type: semantic
                name: status # Name associated with the associated element in a hypermedia response.
                doc: How is the DRD.
                href: http://alps.io/schema.org/Text
                name: status # Overrides attribute in response to be 'name' vs. 'form-status'.
                field_type: select
                enum:
                  - working
                  - renegade
                  - broken
                validators:
                  - presence
              form-kind: # Unique value to differentiate from 'kind' descriptor.
                type: semantic
                name: kind # Name associated with the associated element in a hypermedia response.doc: What kind is it.
                href: http://alps.io/schema.org/Text
                field_type: multi-select
                enum:
                  - standard
                  - sentinel
                validators:
                  - presence 
```

## Descriptor Dependencies
Data descriptors are directly related to [State Descriptors](data_descriptors.md) in a _Resource Descriptor_. Thus, a
data descriptor:

* MUST have a corresponding State descriptor if it includes [Transition Descriptors](transition_descriptors.md).

[Back to Resource Descriptors](resource_descriptors.md)
[Example Resource Descriptor]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
