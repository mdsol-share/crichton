# @title Data Descriptors
# Overview
Data Descriptors define the semantics, or vocabulary, of the data-related attributes of a resource and/or the semantics 
of the data associated with 'forms' in transitions that either template queries for a `safe` transition 
or template bodies in `unsafe` and `idempotent` transitions. 

## Properties
The YAML keys directly under the `semantics`/`parameters` property are the ALPS IDs of the individual descriptors and thus must be
unique within the document. The `name` property can be used to specify the semantic name that will be used in a
response. Otherwise, the ID will be the name of the associated attribute in the representation of the resource.

* \[descriptor_key\] - A YAML key that is the unique ID of the associated ALPS profile.
   * `doc` - The description of the semantic descriptor: REQUIRED.
   * `name` - The name associated with the related element in a response. Overrides the ID of the descriptor as the
  default name: OPTIONAL.
   * `type` - The type of the descriptor. For data related descriptors, only use `semantic`. When data descriptors are 
  grouped under `semantics` or `parameters` tags, the underlying `type` is `semantic`: OPTIONAL
   * `href` - The underlying ALPS profile, either representing another resource or a primitive profile. See 
  [Primitive Profiles](primitive_profiles.md) for more information: REQUIRED.
   * `sample` - A sample data value for use in generating sample representations by media-type: RECOMMENDED.
   * `embed` - Indicates that this resource should be embedded in a response either inline or as a link.
    Valid values are:
      * `single`
      * `multiple`
      * `single-link`
      * `multiple-link`
      * `single-optional`
      * `multiple-optional`
      * `single-optional-link`
      * `multiple-optional-link`

The default, if not specified, is `single`. The values `multiple` and `multiple-link` indicate the item should be
embedded as an array. The values that contain `optional` indicate that the client can request the
way the item is to be embedded. They default to `:link` for if they end with `-link`, to `:embed` otherwise.
The option `:embed_optional` - a hash with string keys as the names and either `:embed` or `:link` as the
values - allows setting the mode of embedding.

## Defining data descriptors
It is possible to define all data descriptors grouped under top-level `semantics` element,
however, it is not a requirement: data descriptors can be defined as a child descriptors of transition elements.
Data descriptors under `parameters` tag of transition element define templated url properties;
data descriptors under `semantics` tag of transition element define template bodies.
Defining data descriptors grouped under a top-level `semantics` element is considered a best practice. Use `parameters` or/and
`semantics` and `href` property to reference already defined data descriptors elements in transitions.
It is also possible to group data descriptors under top-level `data` element, which is an alias to the `semantics` element.
Thus, you can use `data` and `semantics` elements interchangeably.
See examples below.

## Examples
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

### Data descriptors defined under top-level `data` element
```yaml
data:
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


[Back to API Descriptor Document](descriptors_document.md)
[Example API Descriptor Document]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
