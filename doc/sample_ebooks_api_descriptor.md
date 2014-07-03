# @title Sample eBooks API Descriptor

```yaml
#
# An API descriptor document is a declarative configuration file that defines the semantic data,  
# states, and state transitions associated with a particular resource (or set of closely 
# related resources) independent of protocol or media-type. Further, it details implementation specific details
# of the resources for internal use in generating responses.
#
# The following sections facilitate a number of objectives including generating an ALPS profile 
# of the resource(s), generating human readable documents including sample representations and
# decorating service responses.
#
id: EBooks # REQUIRED. Unique id of the document (and the related ALPS profile generated from this document).
doc: Describes the semantics, states and state transitions associated with eBooks.
links:
  self: EBooks # REQUIRED. Can be absolute or relative if 'alps_base_uri' configured in cricton.yml
  help: http:/example.com/EBooks #OPTIONAL. Can be relative path if 'documentation_base_uri' configured in cricton.yml

# Data descriptors define the semantics of all the individual data `descriptor` elements that are the building 
# blocks for the resources defined below in the `resources` section. Separating these at the top is considered a 
# best practice for even though these elements can also be defined directly for each resource since the generated
# ALPS profile reflects this structure.
data:
  total_count: # The ID of the element, also the name unless a `name` property is specified on the descriptor
    doc: The total number of all eBooks # OPTIONAL. Human readable documentation for the descriptor.
    href: http://alps.io/schema.org/Integer # OPTIONAL. References an existing profile.
    sample: 5 # Planned: value to use in generated sample media-type representations
  items:
    doc: An embedded list of individual eBook items
    href: ebook # relative URL references a descriptor in this document. See `resources` ebook below.
    embed: multiple # Indicates multiple ebook resource entities should be embedded as this property
  authors:
    doc: An embedded list of eBook authors
    href: Author#authors  # References descriptor in another local API Descriptor Document with the ID `Authors`
    embed: multiple # Indicates multiple ebook resource entities should be embedded as this property
  name:
    doc: The title of an eBook
    href: http://alps.io/schema.org/Text
    sample: RESTful Web APIs
  text:
    doc: The text of an ebook
    href: http://alps.io/schema.org/Text
    source: content # The local data property containing the value of the `text` attribute of the representation.
    sample: I am going to show you a better way to do distributed computing ...
  status:
    doc: Whether the eBook is a rough draft, draft or published
    href: http://alps.io/schema.org/Text
  author:
    doc: The author of the eBook
    href: Authors#author # References descriptor in another local API Descriptor Document with the ID `Authors`
    embed: optional
  
# Safe descriptors define the ALPS profile `afe` state transitions
safe:
  list: # Transition ID that correlates state transition descriptors and protocol descriptors of the same name
    doc: A list of available eBooks
    rt: ebooks # Profile of the resource returned by the transition. Relative URI indicates defined in this document.
  search:
    doc: Filter a list of eBooks using the search criteria.
    parameters: # Indicates available query parameters on the transition
      - href: name # Reuse the `name` descriptor
      - href: text
        name: search_text # Specifying a name for a descriptor overrides the default name specified by its key
    rt: ebooks
  show: 
    doc: View an eBook
    rt: ebook
  book_author: # Document Unique ID
    doc: Link to the author of the eBook
    name: author # The name of the transition that overrides the ID default
    rt: http://alps.io/schema.org/CreativeWork#author # Indicates a different profile defines this resource.
 
# Idempotent descriptors define the ALPS profile `idempotent` state transitions
idempotent:
  edit:
    doc: Edits an eBook's properties
    data: # Indicates data to be submitted with the transition (form properties #=> body)
      - href: name
        validators: # Adds validators to the data property
          - required
      - href: text
    rt: ebook
  release:
    doc: Promotes an eBook
    rt: ebook
  delete:
    doc: Deletes an eBook

# Unsafe descriptors define the ALPS profile `unsafe` state transitions
unsafe:
  create: 
    doc: Creates a new eBook
    href: edit # Extends local `edit` transition to stay DRY and define other required data
    data: 
     - href: Author#author_url # References a descriptor in a different local API descriptor document with ID `Author`.
       validators:
         - required
    rt: ebook
  copy:
    doc: Copies an eBook
    rt: ebook
 
# Resource descriptors define ALPS profile descriptors of resources vs. building block descriptors. 
resources:
  ebooks:
    descriptors: # References data and transition descriptors that comprise the resource
      - href: total_count
      - href: items
      - href: authors
      - href: list
      - href: search
      - href: create
    
    # States are defined on a particular resource to indicate the state-machine and related conditions.
    # Crichton will only automatically include transitions defined for a state. Further, it will only include
    # transitions with conditions if options[:conditions] (see Getting Started: Know Your Options) contain
    # one of the required conditions.
    states:
      collection:
        doc: The default list of eBooks
        transtions:
          list:
            name: self # Indicates in this state, this transition is the IANA self link relation for the resource
            location: entry # Indicates this transition is a resource entry point to register for discovery
            next: 
              - collection # Exercising this transition moves the resource to the specified state.
          search: &search
            next:
              - navigation
          create: &create
            conditions:
              - can_create_ebook            
            next:
              - rough_draft # Initial state of a created eBook resource 
              - error # Resulting state if there is an error creating an eBook
      navigation:
        doc: A filtered list of eBooks
        transitions:
          list:
            next: 
              - collection
          search:
            <<: *search
            name: self # Self transition for this state
          create: *create
  ebook:
    descriptors: # References data and transition descriptors that comprise the resource
      - href: name
      - href: text
      - href: status
      - href: author
      - href: book_author
      - href: show
      - href: edit
      - href: copy
      - href: delete
      - href: release
    states:
      rough_draft:
        doc: The initial state of an eBook that is private.
        transitions:
          show:
           name: self # Indicates in this state, this transition is the IANA self link relation for the resource
           next:
             - rough_draft
          edit: &edit
            conditions:
              - is_author
            next:
              - rough_draft
              - error
          copy: *edit
          delete:
            <<: *edit
            next:
              - deleted
          release:
            <<: *edit
            next:
              - draft
          author:
            conditions:
              - is_author
            next:
              - location: Author#author # Indicates this is an `application state` transition to a related resource
      draft:
        doc: The state of an eBook that is open for review and discussion.
        transitions:
          show:
            name: self
            next:
              - draft
          edit: &draft_edit
            conditions:
              - is_author
              - can_edit
            next:
              - draft
          copy: 
            conditions:
              - is_author
              - can_create_ebook
              - can_copy
            next:
              - draft
          delete:
            conditions:
              - is_author
              - can_delete
            next:
              - deleted
          release:
            conditions:
              - is_author
              - can_release
            next:
              - published  
          author:
            conditions:
              - is_author
              - can_read
            next:
              - location: Author#author # Indicates this is an `application state` transition to a related resource
      published:
        doc: The published, un-editable version of an eBook
        transitions:
          show:
            name: self
            next:
              - published 
      author:
        next:
          - location: Author#author # Indicates this is an `application state` transition to a related resource
      deleted:
        doc: The eBook is now a memory.
        location: exit # Indicates this is the exit of the related state-machine
      error:
        doc: An error has occured.
      
media_types:
  - application/json
  - application/hal+json
  - application/vnd.hale+json
  - text/html
  - application/xhtml+xml

# Details the protocol specific implementation details of the transitions. Currently, this is redundant with routes. 
# Future versions will support DRYing this out with framework routes functionality, e.g. routes.rb in Rails.
http_protocol:
  list: &list
    uri: ebooks # Relative to the configured deployment_base_uri in crichton.yml
    method: GET
    slt: &slt1 # OPTIONAL. If defined, crichton adds the SLT of the request as a configurable header in responses.
      99th_percentile: 100ms
      std_dev: 25ms
      requests_per_second: 50
  search: *list
  create:
    uri: ebooks
    method: POST
  show:
    uri: ebook/{uuid} # Assumes that an ebook object has a `uuid` property on it to populate this templated URI
    method: GET
    slt: *slt1
  edit:
    uri: ebook
    method: PUT
    slt: &slt2 # OPTIONAL. If defined, crichton adds the SLT of the request as a header in responses.
      99th_percentile: 200ms
      std_dev: 50ms
      requests_per_second: 50
  copy:
    uri: ebook/{uuid}/copy
    method: POST
    slt: *slt2
  release:
    uri: ebook/{uuid}/release
    method: POST
    slt: *slt2
  delete: 
    uri: ebook/{uuid}
    method: DELETE
    slt: *slt1
  author:
    uri_source: author_url # Property on the object that returns the url for the author link
    method: GET
```
