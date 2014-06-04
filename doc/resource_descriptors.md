#Resource Descriptors
## Contents
- [Overview](#overview)
 - [Descriptors Section](#descriptors-section)
 - [States Section](#states-section)
	- [State Properties](#state-properties)
 - [Code Examples](#code-examples)
 - [External References](#external-references)

# Overview
Resources are data descriptor elements that you group under the `resources` tag and define in the [States](#states-section) section. The [Descriptors](#descriptors-section) section also contains semantics and transition descriptors that are available for a resource. 

## Descriptors Section
The `descriptors` section MAY contain a list of referenced data descriptor and transition elements. You can also define semantic and transition elements as child elements grouped under the `descriptors` tag.

## States Section
The `states` section of a _resource_ defines the metadata for a resource's states. Crichton uses descriptors to determine which transitions are available for responses. These responses are a function of the resource state and any conditions that must be satisfied for inclusion in the response. 

NOTE: The `states` section also includes properties to graphically generate the state machine of the resource(s) that are described.

Technically, for any resource there are an infinite number of possible states when one considers that if you change a value of any property it produces a different resource 'state'. However, categorically, there will be a limited set of states associated with a resource. These categories will be associated with different sets of possible transitions that can be exercised on the resource in that state. Thus, when we talk about states in Crichton, we mean the categorical states of the state machine, each state having its own set of available transitions or different permission rules for a given set of transitions.

### State Properties
States can have the following properties.
- `states` - Defines the states associated with each resource. Specified as the keys of this property. The 
actual state names are the keys under the resource.
	- \[state name\] The name of the state.
	- `doc` - Documents a particular state in human-readable form.
	- `transitions` - The transtions that are available for the specified state. These transitions can represent link- or form-based transitions.
		- `name` - Overrides the name to be set on the affordance in a response. Otherwise, Crichton uses the ID - which is the YAML key - for the transition. You must define 'name:self' for at least one transition for the particular state.
		- `location` - The location of the state. Valid values include: `entry`, `exit`, or a URI to an external ALPS type that is associated with the transition. Location here is from an application standpoint versus the resource state standpoint. 
		- `conditions` - An array of conditions that are applied as a Boolean __OR__. This must exist for the transition to be included. When you pass an option that includes a list of satisfied conditions when generating responses, Crichton can determine which state's transitions to provide in a response. These condition strings are defined in your own application's authorization logic and are passed to Crichton. The conditions in the [Code Example](#code-example) are examples only.
		- `next` - An array of next states in the state machine that are possible when the client follows the transition. Typically, this is only one state, unless an error state is a possibility. If you have a transition that is associated with an external hash resource, use a hash with the `location` key and a value that is an ALPS-type that specifies the profile of the external resource.

## Code Example
The following example shows the Descriptors and State sections.

```yaml
resources:
  drds:
    doc: A list of DRDs
    links:
      profile: drds
      help: docs/drds
    descriptors:
      - href: total_count
      - href: items
      - href: list
      - href: search
      - href: create
    states:
      collection:
        doc: The entry point state for interacting with DRDs.
        transitions:
          list:
            name: self
            location: entry
            next:
              - collection
          search:
            next:
              - navigation
          create:
            conditions:
              - can_create 
              - can_do_anything
            next:
              - activated
              - error
      navigation:
        doc: Represents a filtered list of DRDs.
        transitions:
          search:
            name: self
            next:
              - navigation
          create:
            conditions:
              - can_create 
              - can_do_anything
            next:
              - activated
              - error 
```

## Related Topics
- [Back to API Descriptor Document](descriptors_document.md)
- [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
- [Data Descriptors](data_descriptors.md)
