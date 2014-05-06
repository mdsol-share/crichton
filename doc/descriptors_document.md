# @title Resource Descriptor Document
# Overview
A _Resource Descriptor Document_ is a declarative YAML document that profiles the semantics, states, state transitions and 
protocol specific implementations of a single resource, or possibly several closely related resources returned by
Hypermedia APIs powered by Crichton. It details a Domain Application Protocol (DAP) for the referenced resources 
layered on top of the transport protocol(s) supported for the resource(s).

There are a number of key concepts underlying _Resource Descriptor Document_ design and properties:

1. The underlying concept behind the design is the [ALPS specification][], which defines 
a protocol and media-type independent resource semantic profile in a machine-readable format.

2. In principle, a _Resource Descriptor Document_ does not define a schema or actions, but rather the semantics (vocabulary) 
associated with the referenced resource's data and state transitions. As such, it may define terms or it may reference 
external semantic documents as appropriate. Further, it establishes the semantics of the affordances (links and forms)
associated with state transitions for a resource. Again, it may define these or reference external semantic documents.

3. It assumes an external, referenceable source of human-readable semantic documentation of any properties or 
affordances it exposes. A _Resource Descriptor Document_ may be used to generate some of this information, but it presupposes 
the existence of external repositories for any URIs it references.

4. It separates the definition of protocol and media-type information from the semantic definition of the resource 
semantic data and transitions as a RESTful design tool.

5. It facilitates API design in a contract first fashion. By initially focusing on the semantic definitions of a 
resource and its states, an API can be designed and a human-readable contract generated directly from the 
_Resource Descriptor Document_.

The Crichton library parses _Resource Descriptors_ to generate service responses and generate ALPS profiles that can
be included in responses that ALPS-aware Hypermedia agents can consume for different media-types.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and 
"OPTIONAL" in this document are to be interpreted as described in [RFC2119](http://tools.ietf.org/html/rfc2119).

## Purpose
A _Resource Descriptor Document_ serves multiple purposes, including defining:

1. Protocol and media-type independent semantics of resources.
  * Delineates semantic data (properties and optionally embedded resources), semantic links, and transition controls 
  (links and forms).
  * Facilitates generating m2m readable ALPS profiles in XML and JSON.
  * Facilitates generating service responses for different Hypermedia-aware media-types.
2. States and associated state transitions to facilitate generating responses that include complete state 
information.
  * References semantic definitions of transitions.
  * Supports business logic limiting the available transitions in a response.
  * Supports diagramming state machines and registering resources and their relationships as a state machine graph.
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

## Properties
_Resource Descriptor Documents_ are built by specifying a specific set of metadata and properties. Though the document sections 
can be maintained in any order, the example below reflects a structure associated with the progressive design of a 
Hypermedia API:

* Document metadata about the profile
* Analyze the entities, states and transitions associated with the underlying workflow
* Define the semantics of the entities
* Define the semantics of the state transitions
* Define the semantics of any templates (media-type form, in contrast to a link) used in transitions that require a 
formatted body
* Define the particulars of how the transitions are implemented for different protocols
* Define routing/scaffolding information for the resource (OPTIONAL).

[Example Resource Descriptor Document][]

A number of the properties in a _Resource Descriptor Document_ directly correspond to their meaning in the 
[ALPS specification][]. These are:

* `id` - Unless explicitly defined for a particular descriptor, it is defined by the YAML key associated with a 
descriptor.
* `doc` - A human-readable description.
* `href` - The URI of the associated ALPS profile corresponding to the attribute. A relative URI indicates an element
in the current _Resource Descriptor Document_ document.
* `links` - Related links. The YAML keys correspond to a link `rel` attribute and the value with the URI 
specified in the link `href` attribute.
* `name` - Used to specify descriptor names which would otherwise have the same, non-unique `id` (YAML key).
* `rt` - The return type of a transition that is an ALPS profile URI. This can be a relative URI indicating it is 
associated with secondary profile in the existing resource descriptor or fully-qualified fragment URI associated 
with an external ALPS profile. See [ALPS specification][] discussion of `id` for more information.
* `type` - The type of the descriptor. Valid values are `semantic`, `safe`, `unsafe`, or `idempotent`. See 
[ALPS specification][] discussion of `type` for more information.

Other properties are defined in the sections that follow.

* [Profile Metadata](profile_metadata.md)
* [Data Descriptors](data_descriptors.md)
* [Extensions](extensions.md)
* [Transition Descriptors](transition_descriptors.md)
* [Resources](resource_descriptors.md)
* [Media Types](media_types.md)
* [Protocol Descriptors](protocol_descriptors.md)
* [Routes Descriptors](routes_descriptors.md)

[ALPS specification]: http://alps.io/spec/index.html
[Example Resource Descriptor Document]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
