# @title Profile Metadata
# Profile Metadata
The top-level of an _API Descriptor Document_ contains metadata associated with the resource profile itself.

## Properties
* `id` - The ID of the profile as a upper camel-case name of the profile. Used to generate the profile URI: REQUIRED.
* `doc` - Documents the contents of the profile: REQUIRED.
* `links` - Links related to the profile: RECOMMENDED. 
* `version` - The version of the document(for internal use): REQUIRED.

Note: If `profile` and/or `help` links are included as relative links, they will be generated in ALPS profiles as
fully-qualified URIs using `the alps_base_uri` and/or `documentation_base_uri` configuration variables see 
[Crichton Configuration](crichton_configuration.md). Any other link included must specify a fully-qualified URI.

`profile` and `help` are used in accordance to [RFC 5988 - Web Linking](http://tools.ietf.org/html/rfc5988).

## Example
The following example highlights top-section of the [Example Resource Descriptor][]. 

```yaml
id: DRDs
version: v1.0.0
doc: Describes the semantics, states and state transitions associated with DRDs.
links:
  profile: DRDs
  help: Things/DRDs
  custom: http://example.org
```

The associated profile URI would be: http://alps.example.org/DRDs.

[Back to API Descriptor Document](descriptors_document.md)
[Example API Descriptor Document]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
[Crichton Configuration]:(crichton_configuration.md)
