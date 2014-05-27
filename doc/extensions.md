# @title Data Descriptor Extensions

## Contents
- [Overview](#overview)
 - [Data Descriptor Extension Properties](#data-descriptor-extension-properties)
 - [List of Supported Input Types and Validators](#list-of-supported-input-types-and-validators)
 - [Code Examples](#code-examples)
 	- [Defining data descriptor extensions](#defining-data-descriptor-extensions)
 	- [Using data descriptor extensions and extending data descriptors as part of referenced descriptor](#using-data-descriptor-extensions-and-extending-data-descriptors-as-part-of-referenced-descriptor)
 - [External References](#external-references)

# Overview
You can use extensions to augment data descriptor elements with specific information such as field types and their options, as well as validators.

Extensions are grouped under the top-level `extensions` element. The data descriptor extensions section is OPTIONAL, so you can omit it in the API Descriptor Document. However, you can still define extensions as part of referenced data descriptor elements. See the [Code Examples](#code-examples) below.

## Data Descriptor Extension Properties
You can ssign the following properties to extensions. 
NOTE: You can only have one of the `list`, `hash`, or `external` properties. This applies also for `href` entries that you include. In the case of `external`, the `source` element can contain a link to an external resource or method to call on a target object. If `source` is a link to an external resource, you must include `prompt` and `target` elements.
- `options` - Provides a list of possible values for a select list or similar use. Below this key, you can use the following. All are optional, but it is best practice to include as many as apply.
	- `id` - Can be used to reference a particular list and to include its values in another value's entry.
	- `href` - Includes a referenced value's entry.
	- `list` - Contains an array of values.
	- `hash` - Contains a hash of key-value pairs.
	- `external` - Retrieves values from an external source.
	- `target` - Specifies the name of the attribute inside the element that the value will be taken from.
	- `prompt` - Specifies the attribute of the text of the item will be taken from are used to specify the fields that are to be used to assemble the list or hash. In case of a list, the target and prompt are identical.
	- `field_type` - Defines the type of field for the form. Most of the valid input types were borrowed from the [HTML5 specification](http://www.w3.org/html/wg/drafts/html/master/forms.html#the-input-element). 
	- `validators` - Optonal. Hash of validator objects associated with a field.

## List of Supported Input Types and Validators
The following table lists the supported input types and the validators that you can apply to them.

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

(*) `boolean` is a generic input type to use instead of `checkbox`. The HTML5 `checkbox` type doesn't make sense in media-types other than HTML. Therefore, you can replace it with a generic `boolean` type.

## Code Examples
The following two examples show the YAML for extensions:

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
## External References
- [Back to API Descriptor Document](descriptors_document.md)
- [Example API Descriptor Document](/spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
