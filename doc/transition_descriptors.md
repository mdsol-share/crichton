# @title Transition Descriptors
# Overview
The transitions of a descriptor are the semantic descriptions of the state transformation affordances in the profile.
The presence of a nested semantics section indicates the endpoint will involve templating a response, either as
query parameters, or as a body. The YAML keys directly under the `transitions` property are the `id` properties of the 
individual semantic descriptors.

## Properties
* `transitions` - Recursive section that groups transition descriptors: REQUIRED.
* `doc` - The description of the transition descriptor: REQUIRED.
* `type` - The type of transition, either `safe`, `unsafe` or `idempotent` type: REQUIRED.
* `links` - Links related to the transition descriptor: RECOMMENDED.
* `href` - An underlying ALPS profile: OPTIONAL.
* `rt` - The return type, as an absolute or relative URI to an ALPS profile: REQUIRED.
* `field_type` - Defines the type of field for the form. Valid values are `boolean`, `input`, `select`, or 
`multi-select`: REQUIRED.
* `enum` - Defines the options for select field types or references another profile associated with the enum: OPTIONAL.
* `validators` - An array of validator objects associated with a field: OPTIONAL.

Given that transitions have unique ids relative to the same block of transitions, it may be necessary to define
transitions in the context of a semantic descriptor. This would only happen if for some reason, two different resources
in a profile had the same transition name pointing to different endpoints. Ideally, profiles should be designed to
avoid this situation.
