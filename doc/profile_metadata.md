# Profile Metadata
# Overview
The top-level of an _API Descriptor Document_ contains metadata about the resource profile itself.

## Profile Metadata Properties
Profile medtadata properties include the following:
- `id` - Required. The ID of the profile. Enter using the CamelCase standard for the name of the profile. Used to generate the profile URI.
- `version` - Required. The version of the document. Follow versioning standards. For internal use.
- `doc` - Required. Documents the contents of the profile in human-readable form.
- `links` - Recommended. Links related to the profile.
  - `profile` - Used in accordance with [RFC 5988 - Web Linking](http://tools.ietf.org/html/rfc5988).
  - `help` - Used in accordance with [RFC 5988 - Web Linking](http://tools.ietf.org/html/rfc5988).

    Note: When you include `profile` and/or `help` links as relative links, they are generated in ALPS profiles as
fully qualified URIs using the `alps_base_uri` and/or `documentation_base_uri` configuration variables. See the 
[Crichton Configuration](crichton_configuration.md) for more information. Any other link that you include must specify a fully qualified URI.

## Code Example
The following example highlights the top section of the [Example Resource Descriptor][]. In this example, the associated profile URI would be `http://alps.example.org/DRDs`.

```yaml
id: DRDs
version: v1.0.0
doc: Describes the semantics, states, and state transitions associated with DRDs.
links:
  profile: DRDs
  help: Things/DRDs
  custom: http://example.org
```
## Related Links
- [Back to API Descriptor Document](descriptors_document.md)
- [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
- [Crichton Configuration](crichton_configuration.md)
