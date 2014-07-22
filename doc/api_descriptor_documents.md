# @title API Descriptor Documents

# Overview
Crichton supports hypermedia APIs. An _API Descriptor Document_ is a declarative YAML document that profiles the 
semantics, states, state transitions, and protocol-specific implementations of a single resource or possibly several 
closely related resources. The document details a Domain Application Protocol (DAP) for the referenced resources that 
are layered on top of the transport protocol(s) that the resource(s) support.

## Underlying Concepts<a name="underlying-concepts"></a> 
An _API Descriptor Document_ has a number of key concepts underlying its design and properties, including:

- One of the foundations of the structure and elements that an API Descriptor Document is built on is the 
[ALPS][] specification. This specification defines a protocol and media-type independent 
resource semantic profile that is machine-readable.
- In principle, an _API Descriptor Document_ does not define a schema or actions. Instead it defines the semantics or 
"vocabulary" that is associated with the referenced resource's data and state transitions. Therefore, it can define 
terms or it can reference external semantic documents, depending on requirements. Further, it establishes the semantics 
of the affordances - the links and forms - that are associated with a resource's state transitions. Again, it may define 
these or reference an external semantic document.
- The Descriptor Document assumes that it can reference an external, human-readable semantic documentation of any 
properties or affordances such as the links and forms that the Descriptor Document exposes. You can use an _API 
Descriptor Document_ to generate some of the human-readable information; however, the Document presupposes external 
repositories for any URIs that it references.
- The Descriptor Document separates the definition of protocol and media-type information from the semantic definition 
of the resource's semantic data and transitions as a RESTful design tool.
- The Descriptor Document facilitates API design in a contract-first fashion. By focusing on the semantic 
definitions of a resource and its states, you can design an API and generate a human-readable contract directly from 
the _API Descriptor Document_.

The Crichton library uses {file:doc/resource_descriptors.md Resource Descriptors} that are defined in API Descriptor documents to generate service responses and to generate related ALPS profiles. These profiles can further be included in responses that ALPS-aware Hypermedia agents can consume for different media-types.

This document uses key words that follow [RFC2119](http://tools.ietf.org/html/rfc2119) standards. These key words 
include: "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and 
"OPTIONAL".

For more information Descriptor Document elements, see the {file:doc/roadmap.md#design-goals Design Goals} documentation.

## Properties and Examples<a name="properties-and-examples"></a>
_API Descriptor Documents_ are built by specifying a set of metadata and [descriptor elements](#descriptor-elements). 
Though the document sections can be maintained in any order, the following steps reflect a workflow associated with the 
progressive design of a Hypermedia API. 

1. Document metadata about the profile.

2. Analyze the resources, states, and transitions associated with the underlying workflow.

3. Define the semantics of the resources.

4. Define the semantics of the state transitions.

5. Define the semantics of any templates - media-type form, in contrast to a link - used in transitions that require a 
formatted body.

6. Define the particulars of how the transitions are implemented for different protocols.

7. Define routing/scaffolding information for the resource. OPTIONAL.

* {file:doc/sample_ebooks_api_descriptor.md Example eBooks API Descriptor Document}
* {file:spec/fixtures/resource_descriptors/drds_descriptor_v1.yml Example DRDs API Descriptor Document}


## Properties/ALPS Correlation<a name="properties-alps-correlation"></a>
A number of the properties in a _API Descriptor Document_ correspond directly to their related meanings in the 
[ALPS][] specification. These properties include the following:

- `id` - Unless explicitly defined for a particular descriptor, `id` is defined by the YAML key associated with a 
descriptor.
- `doc` - A human-readable description.
- `href` - The URI of the associated ALPS profile that corresponds to the attribute. A relative URI indicates an element 
in another local _API Descriptor Document_.
- `links` - Related links. The YAML keys correspond to a link `rel` attribute and the value with the URI 
specified in the link `href` attribute.
- `name` - Specifies descriptor names that would otherwise have the same, non-unique `id` (also known as the YAML key).
- `rt` - The return type of a transition that is an ALPS-profile URI. This can be a relative URI that indicates it is 
associated with a secondary profile in the existing resource descriptor or fully qualified fragment URI associated 
with an external ALPS profile. See the [ALPS][] specification discussion of `id` for more information.
- `type` - The type of the descriptor. Valid values are `semantic`, `safe`, `unsafe`, or `idempotent`. See the [ALPS][] 
specification discussion of `type` for more information.

## Profile Metadata<a name="profile-metadata"></a>
The top-level of an _API Descriptor Document_ contains metadata about the resource profile itself.

### Properties<a name="properties"></a>
Profile metadata properties include the following:

- `id` - REQUIRED. The ID of the profile. Enter using the CamelCase standard for the name of the profile. Used to 
generate the profile URI.
- `doc` - REQUIRED. Documents the contents of the profile in human-readable form.
- `links` - RECOMMENDED. Links related to the profile.
  - `profile` - Used in accordance with [RFC 5988 - Web Linking](http://tools.ietf.org/html/rfc5988).
  - `help` - Used in accordance with [RFC 5988 - Web Linking](http://tools.ietf.org/html/rfc5988).

    NOTE: When you include `profile` and/or `help` links as relative links, they are generated in ALPS profiles as
fully qualified URIs using the `alps_base_uri` and/or `documentation_base_uri` configuration variables. See 
{file:doc/getting_started.md#configuration Crichton Configuration} for more information. Any other link that you 
include must specify a fully qualified URI.

### Code Example<a name="code-example"></a>
The following example highlights the top section of the 
{file:doc/sample_ebooks_api_descriptor.md Example eBooks API Descriptor Document}. In this example, the associated 
profile URI would be `http://alps.example.org/DRDs`.

```yaml
id: DRDs
version: v1.0.0
doc: Describes the semantics, states, and state transitions associated with DRDs.
links:
  profile: DRDs
  help: Things/DRDs
  custom: http://example.org
```

## Descriptor Elements<a name="descriptor-elements"></a>
The following documents detail the properties of each subsection of an _API Descriptor Document_:

* [Data and Transition Descriptors](data_and_transition_descriptors.md)
* [Resource Descriptors](resource_descriptors.md)
* [Protocol and Route Descriptors](protocol_and_route_descriptors.md)

## Crichton Lint<a name="crichton-lint"></a>
Developing a Hypermedia-aware resource whose behavior is structured within a API Descriptor document may appear 
daunting at first. The development of a well-structured and logically correct resource descriptor document can take 
several iterations.

To help with the design of your hypermedia resources, Crichton has a lint tool that helps you catch major and minor errors in your resource descriptor documents. Single or multiple descriptor files can be validated by way of lint through the rdlint gem executable or rake. For example:

* `bundle exec rdlint -a (or --all) ` Lint validate all files in the resource descriptor directory

* `bundle exec rake crichton:lint[all]` Use rake to validate all files in the resource descriptor directory

To understand all of the details of linting descriptors files, see the {file:doc/lint.md Lint} documentation.

## Related Topics<a name="related-topics"></a>
* [ALPS specification](http://alps.io/spec/index.html)
* [Example eBooks API Descriptor Document](sample_ebooks_api_descriptor.md)
* [Example DRDs API Descriptor Document](spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
* [Data and Transition Descriptors](data_and_transition_descriptors.md)
* [Resource Descriptors](resource_descriptors.md)
* [Protocol and Route Descriptors](protocol_and_route_descriptors.md)  
