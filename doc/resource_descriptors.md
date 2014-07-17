# @title Resource Descriptors

# Overview
You define _Resources_ by grouping individual descriptors under the `resources` tag in an API descriptor document. This includes defining the states of the resource. For example, the following YAML shows a definition for DRDS: 

```yaml
resources:
  drds:
    doc: A list of DRDs
    links:
      profile: drds
      help: docs/drds
    descriptors:
      # The descriptors comprising the resource
    states:
      # The states of the resource
```

## Descriptors <a name="descriptors"></a>
The `descriptors` section of a resource MAY contain a list of referenced [data and transition descriptor][] elements. 
You MAY also define `semantic` and `transition` elements as child elements grouped under the `descriptors` tag versus at 
the top-level of an [_API Descriptor Document_][]. However, it is a best practice to define the individual descriptors 
at the top level so that related ALPS profiles generated for the resources reflect individual descriptors at the 
top level as well.

## States<a name="states"></a>
The `states` section of a _resource_ defines the metadata for a resource's states. Crichton uses descriptors to 
determine what transitions are rendered in responses. These responses are a function of the _resource_ state and any 
conditions that must be satisfied for inclusion in the response. 

Technically, for any _resource_ there are an infinite number of possible states when one considers that if you change a 
value of any property it produces a different resource "state." However, categorically, there will be a limited set of 
states associated with a _resource_. These categories will be associated with different sets of possible transitions 
that can be exercised on the _resource_ in that state. Thus, when we talk about states in Crichton, we mean the 
categorical states of the state machine, with each state having its own set of available transitions or different permission rules for a given set of transitions.

If a _resource_ has only one state, the `states` section of a _resource_ must define `default` as the `state_name` 
property value. Alternately, you can use a custom name when the associated object defines a `state` instance method or attribute accessor.

### State Properties<a name="state-properties"></a>
States can have the following properties:

- `states` - Defines the states associated with each resource. Specified as the keys of this property. The 
actual state names are the keys under the resource.
	- \[state name\] The name of the state.
	- `doc` - Documents a particular state in human-readable form.
	- `transitions` - The transitions that are available for the specified state. These transitions can represent 
	link- or form-based transitions.
		- `name` - Overrides the name to be set on the affordance in a response. Otherwise, Crichton uses the ID - which 
		is the YAML key - for the transition. You must define `name:self` for at least one transition for the particular 
		state.
		- `location` - The location of the state. Valid values include `entry`, `exit`, or a URI to an external ALPS 
		type that is associated with the transition. Location here is from an application standpoint versus the resource 
		state standpoint. 
		- `conditions` - An array of conditions that are applied as a Boolean _OR_. This must exist for the transition 
		to be included. When you pass an option that includes a list of satisfied conditions when generating responses, 
		Crichton can determine which state's transitions to provide in a response. These condition strings are defined 
		in your own application's authorization logic and are passed to Crichton. The conditions in the 
		[Code Example](#code-example) are for reference only. These are basically magic strings that can be passed as 
		`conditions` options when a response is rendered. For more information, see [Know Your Options][].		 
		- `next` - An array of next states in the state machine that are possible when the client follows the 
		transition. Typically, this is only one state, unless an error state is possibile. If you have a transition 
		that is associated with an external hash resource, use a hash with the `location` key and a value that is an 
		ALPS-type that specifies the profile of the external resource.

## Code Example<a name="code-example"></a>
The following example shows the `descriptors` and `states` definitions of a _resource_.

### Resource with multiple states
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
              - can_create # Conditions are determined in the context of a request and passed to render the response
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

### Resource with one ("default") state
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

## Related Topics<a name="related-topics"></a>
- [Back to API Descriptor Documents](api_descriptor_documents.md)
- [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
- [Data and Transition Descriptors](data_and_transition_descriptors.md)

[_API Descriptor Document_]: api_descriptor_documents.md
[data and transition descriptor]: data_and_transition_descriptors.md
[Know Your Options]: know-your-options.md
