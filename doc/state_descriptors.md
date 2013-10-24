# @title State Descriptors
# Overview
The `states` descriptor section of a _Resource Descriptor_ defines the metadata associated with the states of a 
resource. Crichton uses these descriptors to determine which transitions are available for responses as a function of 
the resource state and any conditions that must be satisfied for inclusion. The section also includes properties to 
graphically generate the state machine of the resource(s) described.

Technically, for any resource there are infinite states possible when one considers that changing the value of
any property results in the a different 'state' for the resource. However, categorically, there will be limited set of
states associated with a resource and these categories will be associated with different sets of possible transitions
that can be exercised on the resource in that state. Thus, when we talk about states in Crichton, we mean the 
categorical states of the state machine, each with its own unique set of available transitions.

## Properties
* `states` - Defines the states associated with each resource specified as the keys of this property. The 
actual state names are the keys under the resource.
    * \[state_resource\] The ID (YAML key) of the corresponding data descriptor. See [Data Descriptors][].
        * \[state name\] The name of the state.
            * `doc` - Documents a particular state.
            * `location` - The location of the state. Valid values are `entry`, `exit`, or a URI to an external ALPS type that 
            is associated with the transition from an application vs. resource state standpoint. 
            * `transitions` - The transtions available for the particular state. These can represent link or form based 
            transitions.
                * `name` - Overrides the name to be set on the affordance in a response. Otherwise, the ID (YAML key) for the 
                transition is used.
                * `conditions` - An array of conditions applied as a Boolean __OR__ that must exist for the transtion to be 
                included. By passing an option including a list satisfied conditions when generating responses, Crichton 
                determines which state's transitions should be included in a response. These strings are defined in your
                own applications authorization logic and passed to Crichton (the following conditions are examples only).
                * `next` - An array of next states in the state machine possible by following the transition. Typically, this will be
only one state, unless an error state is a possibility. If a transition is associated with an external a hash resource,
a hash with the `location` key is used and the value is an ALPS type specifing the profile of the external resource.

## Example
The following example highlights a few parts of the [Example Resource Descriptor][] `states` section. In-line comments
are expounded in the structure and some material is removed for simplicity (indicated by # ...). 

```yaml
states:
  drds: # Specifies the resource associated with the following states.
    collection: # Defines 'collection' state of the 'drds' resource.
      doc: The entry point state for interacting with DRDs.
      location: entry
      transitions:
        list: # The ID of the transition that must be defined as a transition descriptor for the resource.
          name: self # Overrides the default value (ID) of the 'rel' attribute of link or 'name' property of a form.
          next: # Indicates the next state of the resource achieved by following the transition.
            - collection # Name of the next state.
        search:
          next:
            - navigation
        create:
          conditions: 
            - can_create # These are simply keys that one defines in an application authorization logic.
            - can_do_anything
          next:
            - activated
            - error   
    navigation: # Defines 'navigation' state of the 'drds' resource.
      doc: Represents a filtered list of DRDs.
      transitions:
        search:
          name: self # Becomes the self link of the 'navigation' state.
          next:
            - navigation
        # ...     
  drd: # Indicates the states of the 'drd' resource
    activated: # Defines 'activated' state of the 'drd' resource.
      doc: The default state of a DRD.
      transitions:
        show:
          name: self
          next:
            - activated # The `self` link always returns the current state.
        deactivate: # An 'activate' transition is never possible in an 'activated' state
          conditions:
            - can_deactivate 
            - can_update 
            - can_do_anything
          next:
            - deactivated
        # ...
        leviathan-link: # ID of a transtion to a related external resource representing a 'leviathan'.
          name: leviathan # Overrides the 'rel' attribute in the associated link.
          next:
            - location: http://alps.io/schema.org/Leviathans#leviathan
        repair-history: # ID of a transtion to a related external resource representing a 'repair-history' resource.
          conditions:
            - can_repair
          next:
            - location: http://alps.io/schema.org/Repais#history
    deactivated: 
      doc: The DRD is shut down.
      transitions:
        show:
          name: self
          next:
            - deactivated
        activate: # A 'deactivate' transition is never possible in an 'deactivated' state
          conditions:
            - can_activate 
            - can_update 
            - can_do_anything
          next:
           - activated
        # ...
    deleted: # Used to indicate the exit of a state machine.
      doc: The DRD is now free-floating in space.
      location: exit
    error:
      doc: An error has occured.
      location: http://alps.io/schema.org/Error
```

## Descriptor Dependencies
State Descriptors are directly related to [Data Descriptors][] in a _Resource Descriptor_. Thus, a
state descriptor:

* MUST have a related Semantic Descriptor whose ID (YAML key) is the same as the value of the \[state_resource\].

State transitions are also directly related to [Transtion Descriptors](transition_descriptors.md) and indirectly to
[Protocol Descriptors](protocol_descriptors.md), which indicate implemenatation details of the transtions. Thus, a 
state descriptor transition:

* MUST have a related Transition Descriptor whose ID (YAML key) is the same as the state transition.
* MAY use a `name` property to override the associated name of the affordance as implemented in a particular 
media-type.

[Back to Resource Descriptors](resource_descriptors.md)
[Example Resource Descriptor]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
[Data Descriptors]: data_descriptors.md
