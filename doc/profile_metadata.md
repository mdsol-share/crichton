# @title Profile Metadata
# Profile Metadata
The top-level of a _Resource Descriptor_ contains metadata associated with the profile itself.

## Properties
* `id` - The ID of the profile as a upper camel-case name of the profile. Used to generate the profile URI: REQUIRED.
* `doc` - Documents the contents of the profile: REQUIRED.
* `links` - Links related to the profile: RECOMMENDED. 
* `version` - The version of the document(for internal use): REQUIRED.

Note: If `self` and/or `help` links are included as relative links, they will be generated in ALPS profiles as
fully-qualified URIs using `the alps_base_uri` and/or `documentation_base_uri`, respectively. Any other link included
in must specify a fully-qualified URI.

`self` and `help` are used in accordance to [RFC 5988 - Web Linking](http://tools.ietf.org/html/rfc5988).

## Example

```yaml
id: DRDs
version: v1.0.0
doc: Describes the semantics, states and state transitions associated with DRDs.
links:
  self: DRDs
  help: Things/DRDs
  custom: http://example.org
```

The associated profile URI would be: http://alps.example.org/DRDs.

[Back to Resource Descriptors](resource_descriptors.md)
