# @title Data Descriptors
# Overview
Data descriptors define the semantics, or vocabulary, of the data-related attributes of a resource and/or the semantics of the data associated with 'forms' in transitions that either template queries for a `safe` transition 
or template bodies in `unsafe` and `idempotent` transitions.

## Properties
The YAML keys, which appear directly under the `semantics`/`parameters` property, are the ALPS IDs of the individual descriptors. Therefore, they must be unique within the document. You can use the `name` property to specify the semantic name that will be used in a response. Otherwise, the ID is the name of the associated attribute in the representation of the resource.

* \[descriptor_key\] - A YAML key that is the unique ID of the associated ALPS profile.
   * `doc` - REQUIRED. The description of the semantic descriptor. 
   * `name` - OPTIONAL. The name associated with the related element in a response. `Name` overrides the ID of the descriptor as the default name. 
   * `type` - OPTIONAL. The type of the descriptor. For data-related descriptors, only use `semantic`. When you group data descriptors under `semantics` or `parameters` tags, the underlying `type` is `semantic`. 
   * `href` - REQUIRED. The underlying ALPS profile, which either represents another resource or a primitive profile. See [Primitive Profiles](primitive_profiles.md) for more information. 
   * `sample` - RECOMMENDED. A sample data value for use in generating sample representations by media-type.
   * `embed` - Indicates that the resource should be embedded in a response either inline or as a link.
      Valid values for `embed` include the following:
       - `single` - Default value when you do not specify another value.
       - `multiple` - Indicates the item should be embedded as an array.
       - `single-link` - Allows setting the mode of embedding.
       - `multiple-link` - Indicates the item should be embedded as an array.
       - `single-optional` - Client can request the way the item is to be embedded.
       - `multiple-optional` - Client can request the way the item is to be embedded.
       - `single-optional-link` - Allows setting the mode of embedding.
       - `multiple-optional-link` - Allows setting the mode of embedding.

      If you do not specify a value for `embed`, the default value is `single`. The values `multiple` and `multiple-link` indicate the item should be embedded as an array. The values that contain `optional` indicate that the client can request the way the item is to be embedded. They default to `:link` for if they end with `-link`, to `:embed` otherwise. The option `:embed_optional` - a hash with string keys as the names and either `:embed` or `:link` as the values - allows setting the mode of embedding.

## Defining data descriptors
You can define all data descriptors grouped under the top-level `semantics` element; however, it is not a requirement. You can define data descriptors as child descriptors of transition elements. Data descriptors under the `parameters` tag of the transition element define templated url properties. Data descriptors under the `semantics` tag of the transition element define template bodies.
Defining data descriptors grouped under a top-level `semantics` element is considered a best practice. Use `parameters` and/or `semantics`, and `href` properties to reference already defined data descriptor elements in transitions. See the examples below.

## Data Descriptor Examples
### Data descriptors defined under top-level `semantics` element
The following example highlights a few parts of the [Example API Descriptor Document][] `semantics` section associated
with data descriptors.

```yaml
semantics:
  total_count:
    doc: The total count of DRDs.
    href: http://alps.io/schema.org/Integer
    sample: 1
  items:
    doc: An array of embedded DRD resources.
    href: http://alps.io/schema.org/Array
    embed: multiple-optional
```

### Referenced data descriptors defined under `parameters` element
```yaml
safe:
  search:
    doc: Returns a list of DRDs that satisfy the search term.
    rt: drds
    parameters:
      - href: name

idempotent:
  update:
    doc: Updates a DRD.
    rt: none
    links:
      profile: DRDs#update
      help: forms/update
    semantics:
      - href: name
```

### Data descriptors defined under `parameters` element
```yaml
safe:
  search:
    doc: Returns a list of DRDs that satisfy the search term.
    rt: drds
    parameters:
      name:
        doc: The name of the DRD.
        href: http://alps.io/schema.org/Text
```

## Related Topics
- [Back to API Descriptor Document](descriptors_document.md)
- [Example API Descriptor Document](.../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
