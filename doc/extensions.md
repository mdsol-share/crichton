# @title Data Descriptors extensions
# Overview
Extensions can be used to extend data descriptor elements with specific information: field type, 
options for select field types and validators. Extensions are grouped under top-level `extensions` element.
Data descriptor extensions section is OPTIONAL and can be omitted. Extensions still can be defined as part 
of referenced data descriptor element. See example below.

### Properties
 * `options` - Provides a list of possible values for a select list or similar use. Below this key, the following
can be used: (all are optional - but skipping all is pointless)
    * `id` - Can be used to reference a particular list and include its values in another values entry.
    * `href` - Include a referenced values entry.
    * `list` - Contains an array of values.
    * `hash` - Contains a hash of key-value pairs.
    * `external` - Retrieves values from an external source.
    * `target` - specifies the name of the attribute inside the element that the value will be taken from
    * `prompt` - specifies the attribute the text of the item will be taken from are used to specify the fields
    that are to be used to assemble the list or hash. In case of a list, the target and prompt are identical.

    Only one of `list`, `hash` or `external` may be present, this applies also for included href entries.
In the case of `external`, the `source` element may contain a link to external resource or method to call on
a target object. If `source` is a link to external resource, `prompt` and `target` elements must be present.

* `field_type` - Defines the type of field for the form. Most of the valid input types were borrowed from the 
[HTML5 specification](http://www.w3.org/html/wg/drafts/html/master/forms.html#the-input-element). 
* `validators` - Hash of validator objects associated with a field: OPTIONAL.

The following table defines list of supported input types and validators which can be applied to it:

| Input types / attributes | required | pattern | maxlength | min/max |
|:----------------:|:----------:|:---------:|:-----------:|:---------:|
| text           | x        | x       | x         |         |
| search         | x        | x       |           |         |
| email          | x        | x       |           |         |
| tel            | x        | x       |           |         |
| url            | x        | x       | x         |         |
| datetime       | x        |         |           | x       |
| time           | x        |         |           | x       |
| date           | x        |         |           | x       |
| month          | x        |         |           | x       |
| week           | x        |         |           | x       |
| time           | x        |         |           | x       |
| datetime-local | x        |         |           | x       |
| number         | x        |         |           | x       |
| boolean(*)     | x        |         |           |         |
| select         | x        |         |           |         |

(*) `boolean` is a generic input type used instead of `checkbox`.
 HTML5 `checkbox` type doesn't make sense in media-types other than HTML and therefore replaced with generic `boolean` type.

### Defining data descriptor extensions
```yaml
semantics:
  name: &name
    doc: The name of the DRD.
    href: http://alps.io/schema.org/Text
  term:
    doc: The terms to search.
    href: http://alps.io/schema.org/Text

extensions:
  # creates an extension descriptor based on semantic descriptor: name
  _name: &_name
    <<: *name
    field_type: text
    sample: drdname
  # creates an extension descriptor based on extension descriptor: _name
  # to be used as extension descriptor in create transition
  # see example below
  _create_name:
    <<: *_name
    validators:
      - required
      - maxlength: 50
  # creates an extension descriptor based on extension descriptor: _name
  # to be used as extension descriptor in update transition
  # see example below
  _update_name:
    <<: *_name
    validators:
      - required
```

### Using data descriptor extensions and extending data descriptors as part of referenced descriptor
```yaml
safe:
  search:
    doc: Returns a list of DRDs that satisfy the search term.
    rt: drds
    parameters:
      - href: name
        ext: _name
      - href: term
      	field_type: text
	    validators:
	      - required
unsafe:
  create:
    doc: Creates a DRD.
    rt: drd
    parameters:
      - href: name
        ext: _create_name
idempotent:
  update:
    doc: Returns a list of DRDs that satisfy the search term.
    rt: drds
    parameters:
      - href: name
        ext: _update_name
```

[Back to API Descriptor Document](descriptors_document.md)
[Example API Descriptor Document]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
