# Crichton Design Goals for API Descriptor Document

An [API Descriptor Document](descriptors_document.md) serves several purposes. These purposes include defining the following items:

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
 
