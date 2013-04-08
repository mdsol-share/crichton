# Overview
A _Resource Descriptor_ is a declarative YAML document that profiles the semantics, states, state transitions and 
protocol specific implementations of a single resource, or possibly several closely related resources returned by
Hypermedia APIs. It details a Domain Application Protocol (DAP) for the referenced resources layered on top of the 
transport protocol(s) supported for the resource.

There are a number of key concepts underlying it's design and properties:

1. In principle, it does not define a schema or actions, but rather the semantics (vocabulary) associated with the 
referenced resource's data and state transitions. As such, it may define terms or it may reference external semantic 
documents as appropriate. Further, it establishes the semantics of the affordances associated with state transitions 
for the resource. Again, it may define these or reference external semantic documents.

2. The underlying concept behind the design is the [ALPS specification](), which defines a protocol and media-type 
independent resource semantic profile in a machine-readable format.

3. It assumes an external, referenceable source of human-readable semantic documentation of any properties or 
affordances it exposes. A _Resource Descriptor_ may be used to generate some of this information, but it presupposes 
the existence of external repositories for any URIs it references.

4. It separates the definition of protocol and media-type information from the semantic definition of the resource data 
and transitions as a RESTful design approach.

5. It facilitates API design in a contract first fashion. By initially focusing on the semantic definitions of a 
resource and its states, an API can be designed and a human-readable contract generated directly from the 
_Resource Descriptor_.

The Crichton library parses _Resource Desciptors_ to generate service responses and in 
consume service responses in Hypermedia agents for different media-types.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and 
"OPTIONAL" in this document are to be interpreted as described in [RFC2119](http://tools.ietf.org/html/rfc2119).

## Purpose
A _Resource Descriptor_ serves multiple purposes, including defining:

1. Protocol and media-type independent semantics of resources.
  * Delineates semantic data (properties and optionally embedded resources), semantic links, and transition controls 
  (links and forms).
  * Facilitates generating m2m readable ALPS profiles in XML and JSON.
  * Facilitates generating service responses for different Hypermedia-aware media-types.
2. States and associated state transitions to facilitate generating responses that include complete state 
information.
  * References semantic definitions of transitions.
  * Supports business logic limiting the available transitions.
3. Protocol specific idioms associated with a resource.
  * E.g., for HTTP the methods, headers, and status codes. 
  * Facilitates generating form controls that are protocol-dependent.
4. Documentation related descriptions and references for generating human-readable documentation.
  * Includes sample data values for generating sample representations in supported media-types.
  * Includes protocol specific documentation.
5. Routing metadata to generate routes and scaffold models and controllers.
6. Testing metadata to facilitate testing a service or external resource dependencies:
  * Factory generation of mock resources for testing.
  * Services self-testing resources.

# Properties
_Resource Descriptors_ are built by specifying a specific set of metadata and attributes. Though the document sections 
can be maintained in any order, the example below reflects a structure associated with the progressive design of a 
Hypermedia API:

* Document metadata about the profile
* Analyze the entities, states and transitions associated with the underlying workflow
* Define the semantics of the entities
* Define the semantics of the state transitions
* Define the semantics of any templates used in transitions that require a formatted body
* Define the particulars of how the transitions are implemented for different protocols
* Define routing/scaffolding information for routing or scaffolding the resource.

[Example Resource Descriptor](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)

A number of the properties in a _Resource Descriptor_, directly correspond to their meaning in the 
[ALPS specification](). These are:

* `id` - Unless explicitly defined for a particular descriptor, it is defined by the YAML key associated with the 
descriptor.
* `doc` - A human-readable description.
* `href` - The URI of the associated ALPS profile corresponding to the attribute. A relative URI indicates an element
in the resource descriptor.
* `links` - Related links. The YAML keys correspond to the link `rel` attribute associated with the URI specified in
the `href` attribute.
* `name` - Used to disambiguate descriptors with the same `id`.
* `rt` - The return type of a transition.
* `type` - The type of descriptor. Valid values are `semantic`, `safe`, `unsafe`, or `idempotent`.

Other properties are define in the relevant sections that follow.

## Profile Metadata
The top-level of a _Resource Descriptor_ contains metadata associated with the profile itself.

* `id`- The ID of the profile as a upper camel-case name of the profile. Used to generate the profile URI:  REQUIRED.
* `doc`- Documents the contents of the profile: REQUIRED.
* `links` - Links related to the profile: RECOMMENDED. 

  Note: In order to dereference URIs in the document to point to the base ALPS location, use `alps_base`. To
  reference the human-readable documentation base, use `documentation_base`.
* `version` - The version of the document(for internal use): REQUIRED.

## States
TODO

## Semantics
The semantics, or vocabulary, of a particular resource. The YAML keys directly under the `semantics` 
property are the `id` properties of the individual semantic descriptors.

* `semantics` - Recursive section that groups semantic descriptors. All descriptors in this section default to the 
ALPS type `semantic`: REQUIRED.
* `doc` - The description of the semantic descriptor: REQUIRED.
* `links` - Links related to the semantic descriptor: RECOMMENDED.
* `href` - The underlying ALPS profile, either representing another resource or primitive profile. See 
[Primitive Profiles recognized by Crichton]() for more information: REQUIRED.
* `sample` - A sample data value for use in generating sample representations by media-type: RECOMMENDED.
* `embed` - Indicates that this resource should be embedded in a response. Valid values are `single`, `multiple`, and
`optional`. The default, if not specified, is `single`. The value `multiple` indicates the item should be embedded as 
an array. The value `optional` indicates this property should only be included is specifically requested using an 
associated transition that specifies its optional inclusion: OPTIONAL.

## Transitions
The transitions of a descriptor are the semantic descriptions of the state transformation affordances in the profile.
The presence of a nested semantics section indicates the endpoint will involve templating a response, either as
query parameters, or as a body. The YAML keys directly under the `transitions` property are the `id` properties of the 
individual semantic descriptors.

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

## Protocols
Defines the protocol specific implementation of the transitions defined semantically for the resource(s) in the 
profile. Currently, only `http` is implemented. Each transitions must be defined in a protocol section, although 
they may be implemented in different protocols.

* `slt` - The Service Level Target (SLT) for the endpoint: OPTIONAL.

### HTTP
The following properties apply to HTTP protocol definitions.

* `uri` - The URI of the endpoint. If templated, the object being represented must contain an attribute with the
templated parameter(s): REQUIRED.
* `entry_point` - If `true` indicates a resource entry point: OPTIONAL.
* `method` - The uniform interface method: REQUIRED.
* `content_types` - The media-types that are returned as representations of the resource. Used to populate the type
attribute in links as hints to the available media-types: OPTIONAL.
* `headers` - Any headers to be set on responses: OPTIONAL.
* `status_codes` - The status codes that may be returned by this endpoint and what they mean: OPTIONAL.

## Routes
TODO
