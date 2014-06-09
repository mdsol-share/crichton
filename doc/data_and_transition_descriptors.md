# @title Data and Transition Descriptors

## Contents
- [Overview](#overview)
 - [Data Descriptors](#data-descriptors)
  - [Data Descriptor Properties](#data-descriptor-extension-properties)
  - [Defining Data Descriptors](#defining-data-descriptors)
 - [Transition Descriptors](#transition-descriptors)
  - [Properties](#data-descriptor-extension-properties)
  - [dependencies](#defining-data-descriptors)
 - [Data Descriptor Extensions](#data-descriptor-extensions)
  - [Properties](#data-descriptor-extension-properties)
  - [List of Supported Input Types and Validators](#list-of-supported-input-types-and-validators)
  - [Code Examples](#code-examples)
 	 - [Defining data descriptor extensions](#defining-data-descriptor-extensions)
 	 - [Using data descriptor extensions and extending data descriptors as part of referenced descriptor](#using-data-descriptor-extensions-and-extending-data-descriptors-as-part-of-referenced-descriptor)
 - [External References](#external-references)

# Overview
Data and Transition Descriptors are the building blocks of [Resource Descriptors](doc/resource_descriptor.md).

## Data Descriptors
Data descriptors define the semantics, or vocabulary, of the data-related attributes of a resource and/or the semantics 
of the data associated with 'forms' in transitions that either template queries for a `safe` transition or template 
bodies in `unsafe` and `idempotent` transitions.

### Data Descriptor Properties
The YAML keys, which appear directly under the `semantics`/`parameters` property, are the ALPS IDs of the individual 
descriptors. Therefore, they must be unique within the document. You can use the `name` property to specify the semantic 
name that will be used in a response. Otherwise, the ID is the name of the associated attribute in the representation 
of the resource.

* \[descriptor_key\] - A YAML key that is the unique ID of the associated ALPS profile.
   * `doc` - REQUIRED. The description of the semantic descriptor. 
   * `name` - OPTIONAL. The name associated with the related element in a response. `Name` overrides the ID of the 
   descriptor as the default name. 
   * `type` - OPTIONAL. The type of the descriptor. For data-related descriptors, only use `semantic`. When you group 
   data descriptors under `semantics` or `parameters` tags, the underlying `type` is `semantic`. 
   * `href` - REQUIRED. The underlying ALPS profile, which either represents another resource or a primitive profile. 
   See [Primitive Profiles](primitive_profiles.md) for more information. 
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

      If you do not specify a value for `embed`, the default value is `single`. The values `multiple` and 
      `multiple-link` indicate the item should be embedded as an array. The values that contain `optional` 
      indicate that the client can request the way the item is to be embedded. They default to `:link` for if they end 
      with `-link`, to `:embed` otherwise. The option `:embed_optional` - a hash with string keys as the names and 
      either `:embed` or `:link` as the values - allows setting the mode of embedding.

### Defining Data Descriptors

You can define all data descriptors grouped under the top-level `semantics` element; however, it is not a requirement. 
You can define data descriptors as child descriptors of transition elements. Data descriptors under the `parameters` 
tag of the transition element define templated url properties. Data descriptors under the `semantics` tag of the 
transition element define template bodies.
Defining data descriptors grouped under a top-level `semantics` element is considered a best practice. Use `parameters` 
and/or `semantics`, and `href` properties to reference already defined data descriptor elements in transitions. Thus, 
you can use `data` and `semantics` elements interchangeably. See the examples below.

### Data Descriptor Examples
#### Data descriptors defined under top-level `semantics` element
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

#### Data descriptors defined under top-level `data` element
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

#### Referenced data descriptors defined under `parameters` element
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

#### Data descriptors defined under `parameters` element
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

## Transition Descriptors
Transition descriptors define the semantics of the state transformation affordances in the profile. There are three 
types of transitions: `safe`, `unsafe`, and `idempotent`. You can group transitions by their type under the 
corresponding top-level element.

### Transition Properties
- `transition_type` - Required. Section that groups transition descriptors by type.
 - \[alps_id\] - A YAML key that is the unique ID of the associated ALPS profile.
   - `doc` - Required. A human-readable description of the transition descriptor.
    - `name` - Optional. The name associated with the related element in a response. Overrides the ID of the descriptor 
    as the default name.
    - `links` - Recommended. Links related to the transition descriptor.
    - `href` - Optional. An underlying ALPS profile.
    - `rt` - Required. The return type; enter as an absolute or relative URI to an ALPS profile.

### Dependencies
Transition descriptors relate directly to elements in the [Protocol Descriptors](protocol_descriptors.md) and to the 
states section of [Resource Descriptors](resource_descriptors.md#states). These sections indicate implementation details 
of the transtions. Thus, dependencies for a transition descriptor include the following:

- Must have a related Protocol Descriptor whose ID - the YAML key - is the same as some transition.
- Must use a `name` property to override the associated name of the affordance as implemented in a specific media-type.
- SHOULD use a `name` property to override the associated name of the affordance as implemented in a particular 
media-type if the ID of the descriptor is not the required semantic of the descriptor, and is rather a uniqueified ID.
- Must have a related transition in a State Descriptor for the associated resource.

### Code Example
The following example highlights a few parts of the 
[Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml) sections associated with 
transition descriptors and any related data descriptors. In-line comments are expounded in the structure and some 
material is removed for simplicity, indicated by # ... . 

```yaml
safe:
  list:
    doc: Returns a list of DRDs.
    name: self
    rt: drds
  search:
    doc: Returns a list of DRDs that satisfy the search term.
    rt: drds
    parameters:
      - href: name
        ext: _name
      - href: term
        field_type: text

idempotent:
  activate:
    doc: Activates a DRD if it is deactivated.
    rt: drd
  deactivate:
    doc: Deactivates a DRD if it is activated.
    rt: drd

unsafe:
  create:
    doc: Creates a DRD.
    rt: drd
    links:
      profile: DRDs#create
      help: Forms/create
    href: update
    parameters:
      - href: name
        ext: _create_name
      - href: leviathan_uuid
        field_type: text
      - href: leviathan_health_points
        field_type: number
        validators:
          - required
          - min: 0
          - max: 100
        sample: 42
      - href: leviathan_email
        field_type: email
        validators:
          - required
          - pattern: "^.+@.+$"
```

## Data Descriptor Extensions 
You can use extensions to augment data descriptor elements with specific information such as field types and their 
options, as well as validators.

Extensions are grouped under the top-level `extensions` element. The data descriptor extensions section is OPTIONAL, 
so you can omit it in the API Descriptor Document. However, you can still define extensions as part of referenced data descriptor elements. See the [Code Examples](#code-examples) below.

### Properties
You can ssign the following properties to extensions. 
NOTE: You can only have one of the `list`, `hash`, or `external` properties. This applies also for `href` entries that 
you include. In the case of `external`, the `source` element can contain a link to an external resource or method to 
call on a target object. If `source` is a link to an external resource, you must include `prompt` and `target` elements.
- `options` - Provides a list of possible values for a select list or similar use. Below this key, you can use the 
following. All are OPTIONAL, but it is best practice to include as many as apply.
	- `id` - Can be used to reference a particular list and to include its values in another value's entry.
	- `href` - Includes a referenced value's entry.
	- `list` - Contains an array of values.
	- `hash` - Contains a hash of key-value pairs.
	- `external` - Retrieves values from an external source.
	- `target` - Specifies the name of the attribute inside the element that the value will be taken from.
	- `prompt` - Specifies the attribute of the text of the item will be taken from are used to specify the fields that 
	are to be used to assemble the list or hash. In case of a list, the target and prompt are identical.
	- `field_type` - Defines the type of field for the form. Most of the valid input types were borrowed from the 
	[HTML5 specification](http://www.w3.org/html/wg/drafts/html/master/forms.html#the-input-element). 
	- `validators` - OPTIONAL. Hash of validator objects associated with a field.

### List of Supported Input Types and Validators
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

(*) `boolean` is a generic input type to use instead of `checkbox`. The HTML5 `checkbox` type doesn't make sense in 
media-types other than HTML. Therefore, you can replace it with a generic `boolean` type.

### Code Examples
The following two examples show the YAML for extensions:

#### Defining data descriptor extensions
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

#### Using data descriptor extensions and extending data descriptors as part of referenced descriptor
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

## Related Topics
- [Back to API Descriptor Document](api_descriptor_documents.md)
- [Example API Descriptor Document](.../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
