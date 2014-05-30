#@ title Resource descriptors
# Overview
Resources are data descriptor elements which are grouped under `resources` tag and define `states` section. 
Resources also define `descriptors` section which contains semantics and transition descriptors available for 
this resource. 

## States section
The `states` section of a _resource_ defines the metadata associated with the states of a 
resource. Crichton uses these descriptors to determine which transitions are available for responses as a function of 
the resource state and any conditions that must be satisfied for inclusion. The section also includes properties to 
graphically generate the state machine of the resource(s) described.

Technically, for any resource there are infinite states possible when one considers that changing the value of
any property results in the a different 'state' for the resource. However, categorically, there will be limited set of
states associated with a resource and these categories will be associated with different sets of possible transitions
that can be exercised on the resource in that state. Thus, when we talk about states in Crichton, we mean the 
categorical states of the state machine, each with its own unique set of available transitions.

If a resource has only one state, the `states` section of a _resource_ must define `default` as the `state_name`
property value. Alternately, a custom name can be used when the associated object defines a `state` instance method or
attribute accessor that returns the custom name.

## State properties
* `states` - Defines the states associated with each resource specified as the keys of this property. The 
actual state names are the keys under the resource.
	* \[state name\] The name of the state or `default` for resources with only one state.
        * `doc` - Documents a particular state.
        * `location` - The location of the state. Valid values are `entry`, `exit`, or a URI to an external ALPS type that 
        is associated with the transition from an application vs. resource state standpoint. 
        * `transitions` - The transtions available for the particular state. These can represent link or form based 
        transitions.
            * `name` - Overrides the name to be set on the affordance in a response. Otherwise, the ID (YAML key) for the 
            transition is used. 'name:self' MUST be defined for at least one transition for the particular state.
            * `conditions` - An array of conditions applied as a Boolean __OR__ that must exist for the transtion to be 
            included. By passing an option including a list satisfied conditions when generating responses, Crichton 
            determines which state's transitions should be included in a response. These strings are defined in your
            own applications authorization logic and passed to Crichton (the following conditions are examples only).
            * `next` - An array of next states in the state machine possible by following the transition. Typically, this will be
only one state, unless an error state is a possibility. If a transition is associated with an external a hash resource,
a hash with the `location` key is used and the value is an ALPS type specifing the profile of the external resource.

## Descriptors
The `descriptors` section MAY contain a list of referenced data descriptor and transition elements. It is also possible to define
semantic and transition elements as child elements grouped under `descriptors` tag.

## Example

### Resource with multiple states.
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

### Resource with one ("default") state.
```yaml
resources:
 drd:
    doc: Diagnostic Repair Drones or DRDs are small robots that move around Leviathans. They are built by a Leviathan as it grows.
    links:
      self: DRDs#drd
    descriptors:
      - href: uuid
      - href: name
    states:
      default:
        show:
          name: self
          next:
            - default
        update:
            conditions:
              - can_update
            next:
              - default
```

[Back to API Descriptor Document](descriptors_document.md)
[Example API Descriptor Document]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
[Data Descriptors]: data_descriptors.md
