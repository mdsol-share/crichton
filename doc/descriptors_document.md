# @title API Descriptor Document
## Contents
- [Overview](#overview)
 - [Document Descriptor Underlying Concepts](#document-descriptor-underlying-concepts)
 - [Purposes of an API Descriptor Document](#purpose-of-an-API-descriptor-document)
 - [API Descriptor Document Properties and Examples](#API-descriptor-document-properties-and-examples)
 - [API Descriptor Document Properties/ALPS Correlation](#API-descriptor-document-properties/ALPS-Correlation)
 - [External References](#external-references)

# Overview
Crichton supports hypermedia APIs. An _API Descriptor Document_ is a declarative YAML document that profiles the semantics, states, state transitions, and protocol-specific implementations of a single resource or possibly several closely related resources, which Crichton supports. The API Descriptor Document details a Domain Application Protocol (DAP) for the referenced resources that are layered on top of the transport protocol(s) that the resource(s) support.

## Document Descriptor Underlying Concepts
An _API Descriptor Document_ has a number of key concepts underlying its design and properties. These concepts include the following:
- A major concept behind the design of an API Descriptor Document is the [ALPS specification](http://alps.io/spec/index.html). This specification defines a protocol and media-type independent resource semantic profile that is machine-readable.
- In principle, an _API Descriptor Document_ does not define a schema or actions. Instead it defines the semantics or "vocabulary" that is associated with the referenced resource's data and state transitions. Therefore, it can define terms or it can reference external semantic documents, depending on requirements. Further, it establishes the semantics of the affordances, the links and forms, that are associated with a resource's state transitions. Again, it may define these or reference an external semantic document.
- The Descriptor Document assumes that it can reference an external, human-readable semantic documentation of any properties or affordances such as the links and forms that the Descriptor Document exposes. You can use an _API Descriptor Document_ to generate some of human-readable information; however, the Document presupposes external repositories for the URIs that it references.
- The Descriptor Document separates the definition of protocol and media-type information from the semantic definition of the resource's semantic data and transitions as a RESTful design tool.
- The Descriptor Document facilitates API design in a contract-first fashion. By first focusing on the semantic definitions of a resource and its states, you can design an API and generate a human-readable contract directly from the _API Descriptor Document_.

The Crichton library parses _Resource Descriptors_ to generate service responses and to generate ALPS profiles. These profiles can further be included in responses that ALPS-aware Hypermedia agents can consume for different media-types.

This document uses key words that follow [RFC2119](http://tools.ietf.org/html/rfc2119) standards. These key words include: "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and 
"OPTIONAL".

## Purposes of an API Descriptor Document
An _API Descriptor Document_ serves multiple purposes. These purposes include defining the following items:

- Protocol and media-type independent semantics of resources.
 - Delineates semantic data (properties and optionally embedded resources), semantic links, and transition controls 
  (links and forms).
 - Facilitates generating machine-to-machine readable ALPS profiles in XML and JSON.
 - Facilitates generating service responses for [supported Hypermedia-aware media-types](doc/media_type.md).
- States and associated state transitions to facilitate generating responses that include complete state 
information.
 - References semantic definitions of transitions.
 - Supports business logic limiting the available transitions in a response.
 - Supports diagramming state machines and registering resources and their relationships as a state machine graph.
- Protocol-specific idioms associated with a resource.
 - These can include idioms such as HTTP methods, headers, and status codes. 
 - Facilitates generating form controls that are protocol-dependent.
- Documentation-related descriptions and references for generating human-readable documentation.
 - Includes sample data values for generating sample representations in supported media-types.
 - Includes protocol-specific documentation.
- Routing metadata to generate routes and scaffold models and controllers.
- Testing metadata to facilitate testing service or external resource dependencies:
 - Factory generation of mock resources for testing.
 - Services self-testing resources.

## API Descriptor Document Properties and Examples
_API Descriptor Documents_ are built by specifying a set of metadata and properties. Though the document sections can be maintained in any order, the following steps reflect a workflow associated with the progressive design of a Hypermedia API. 
1. Document metadata about the profile.

2. Analyze the resources, states and transitions associated with the underlying workflow.

3. Define the semantics of the resources.

4. Define the semantics of the state transitions.

5. Define the semantics of any templates (media-type form, in contrast to a link) used in transitions that require a 
formatted body.

6. Define the particulars of how the transitions are implemented for different protocols.

7. Define routing/scaffolding information for the resource. OPTIONAL.

[Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)

## API Descriptor Document Properties/ALPS Correlation
A number of the properties in a _API Descriptor Document_ correspond directly to their related meanings in the 
[ALPS specification](http://alps.io/spec/index.html). These properties include the following:
- `id` - Unless explicitly defined for a particular descriptor, `id` is defined by the YAML key associated with a 
descriptor.
- `doc` - A human-readable description.
- `href` - The URI of the associated ALPS profile that corresponds to the attribute. A relative URI indicates an element in another local _API Descriptor Document_.
- `links` - Related links. The YAML keys correspond to a link `rel` attribute and the value with the URI 
specified in the link `href` attribute.
- `name` - Specifies descriptor names that would otherwise have the same, non-unique `id` (also known as the YAML key).
- `rt` - The return type of a transition that is an ALPS-profile URI. This can be a relative URI that indicates it is 
associated with a secondary profile in the existing resource descriptor or fully qualified fragment URI associated 
with an external ALPS profile. See the [ALPS specification](http://alps.io/spec/index.html) discussion of `id` for more information.
- `type` - The type of the descriptor. Valid values are `semantic`, `safe`, `unsafe`, or `idempotent`. See the [ALPS specification](http://alps.io/spec/index.html) discussion of `type` for more information.

## External References
Click the following links to view documents that detail the properties of each subsection of an _API Descriptor Document_:

- [Profile Metadata](profile_metadata.md)
- [Data Descriptors](data_descriptors.md)
- [Transition Descriptors](transition_descriptors.md)
- [Resources](resource_descriptors.md)
- [Extensions](extensions.md)
- [Media Types](media_types.md)
- [Protocol Descriptors](protocol_descriptors.md)
- [Routes Descriptors](routes_descriptors.md)
- [ALPS specification](http://alps.io/spec/index.html)
- [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
