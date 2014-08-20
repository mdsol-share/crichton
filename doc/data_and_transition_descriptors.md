# @title Data and Transition Descriptors

# Overview
Data and Transition Descriptors are the building blocks of [Resource Descriptors](doc/resource_descriptor.md).

## Data Descriptors<a name="data-descriptors"></a>
Data descriptors define the semantics or "vocabulary" of the data-related attributes of a resource and/or the semantics 
of the data associated with `forms` in transitions that either template queries for a `safe` transition or template 
bodies in `unsafe` and `idempotent` transitions. 

### Data Descriptor Properties<a name="data-descriptor-properties"></a>
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
   * `href` - REQUIRED. The underlying ALPS profile, which either represents another resource or a [ALPS][] profile. 
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

      NOTE: If you do not specify a value for `embed`, the default value is `single`. The values `multiple` and `multiple-link` indicate that the item should be embedded as an array. The values that contain `optional` indicate that the client can request the way the item is to be embedded. They default to `:link` if they end with `-link`, otherwise they default to `:embed`. The option `:embed_optional` - a hash with string keys as the names and either `:embed` or `:link` as the values - allows setting the mode of embedding.

### Defining Data Descriptors

You can define all data descriptors grouped under the top-level `semantics` element; however, it is not a requirement. 
You can define data descriptors as child descriptors of transition elements. Data descriptors under the `parameters` 
tag of a transition element define templated url properties. Data descriptors under the `semantics` tag of a 
transition element define template bodies.

A best practice while designing your data descriptors is to group them under a top-level `semantics` element. Use `parameters` and/or `semantics`, and `href` properties to reference already defined data descriptor elements in transitions. Thus, you can use `data` and `semantics` elements interchangeably. See the examples below.

### Examples

The following examples provide details for defining data descriptors.

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
- `transition_type` - REQUIRED. Section that groups transition descriptors by type.
 - \[alps_id\] - A YAML key that is the unique ID of the associated ALPS profile.
   - `doc` - REQUIRED. A human-readable description of the transition descriptor.
    - `name` - OPTIONAL. The name associated with the related element in a response. Overrides the ID of the descriptor 
    as the default name.
    - `links` - RECOMMENDED. Links related to the transition descriptor.
    - `href` - OPTIONAL. An underlying ALPS profile.
    - `rt` - REQUIRED. The return type; enter as an absolute or relative URI to an ALPS profile.

### Dependencies
Transition descriptors relate directly to elements in the [Protocol Descriptors][] and to the States section of 
[Resource Descriptors](resource_descriptors.md#states). These sections indicate implementation details 
of the transitions. Thus, dependencies for a transition descriptor include the following:

- MUST have a related Protocol Descriptor whose ID - the YAML key - is the same as some transition.
- MUST use a `name` property to override the associated name of the affordance as implemented in a specific media-type.
- MUST have a related transition in a State Descriptor for the associated resource.

### Code Example
The following example highlights a few parts of the [Example API Descriptor Document][] sections associated with 
transition descriptors and any related data descriptors. Some material is removed for simplicity. 

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
        ext: input_field
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
        ext: validated_input_field
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

Group extensions under the top-level `extensions` element. The data descriptor extensions section is OPTIONAL, so you can omit it in the API Descriptor Document. However, you can still define extensions as part of referenced data descriptor elements. See the [Code Examples](#code-examples).

### Properties
You can assign the following properties to extensions:

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

See the [Code Examples](#specifying-select-lists).

- `field_type` - Defines the type of field for the form. Most of the valid input types were borrowed from the 
	[HTML5 specification](http://www.w3.org/html/wg/drafts/html/master/forms.html#the-input-element). 
- `validators` - OPTIONAL. Hash of validator objects associated with a field.
- `cardinality` - OPTIONAL. Specifies whether multiple items are allowed. Possible values are `multiple` or `single`. `single` is implied by default. Most common use case is specifying array of objects to be included into the form. 

	NOTE: You can only have one of the `list`, `hash`, or `external` properties. This applies also for `href` entries that you include. In the case of `external`, the `source` element can contain a link to an external resource or method to call on a target object. If `source` is a link to an external resource, you must include `prompt` and `target` elements.

### List of Supported Input Types and Validators
The following table lists the supported input types and the validators that you can apply to them.

| Input types / attributes | required | pattern | maxlength | min/max |
|:------------------------:|:--------:|:-------:|:---------:|:-------:|
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

### Code Examples<a name="code-examples"></a>
The following two examples show the YAML for extensions.

#### Defining data descriptor extensions

```yaml
semantics:
  name:
    doc: The name of the DRD.
    href: http://alps.io/schema.org/Text
  term:
    doc: The terms to search.
    href: http://alps.io/schema.org/Text

extensions:
  # creates an extension descriptor input_field
  input_field: &_input_field
    field_type: text
    sample: drdname
  # creates an extension descriptor based on extension descriptor: input_field
  # to be used as extension descriptor in create transition
  # see example below
  validated_input_field:
    <<: *_input_field
    validators:
      - required
      - maxlength: 50
```

#### Using data descriptor extensions and extending data descriptors as part of referenced descriptor

```yaml
safe:
  search:
    doc: Returns a list of DRDs that satisfy the search term.
    rt: drds
    parameters:
      - href: name
        ext: input_field
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
        ext: validated_input_field
idempotent:
  update:
    doc: Returns a list of DRDs that satisfy the search term.
    rt: drds
    parameters:
      - href: name
        ext: validated_input_field
```

The following two examples show how to use cardinality attribute.

### Using cardinality attribute to specify simple bulk create form
```yaml
unsafe:
  bulk_create:
    doc: Creates a list of drds using collection of names.
    data:
      - href: name
        cardinality: multiple
    rt: drds
```

### Using cardinality attribute to specify bulk create form using complex object
```yaml
unsafe:
  bulk_create:
    doc: Creates a list of drds using collection of drd properties.
    data:
      - href: drd
        cardinality: multiple
    rt: drds
```

### Specifying select lists<a name="specifying-select-lists"></a>
Crichton supports two ways of specifying values for select lists. For a smaller lists, it is possible to specify data in an API Descriptor Document directly:

* Simple list of possible values:
```yaml
unsafe:
  create:
    data:
      location:
        doc: The area the DRD is currently in
        href: http://alps.io/schema.org/Text
        field_type: select
        options:
          list:
            - Nibiru
            - Kronos
            - Vulcan  
```

* Simple collection of key/value pairs:
```yaml
unsafe:
  create:
    data:
      location:
        doc: The area the DRD is currently in
        href: http://alps.io/schema.org/Text
        field_type: select
        options:
          hash:
            planet1: Nibiru
            planet2: Kronos
            planet3: Vulcan  
```

However, for a bigger lists it may not be the best solution. Crichton supports decorating [Service Objects][] with methods, which when called will return either `list`, `hash` or reference to `external` resource:

* Specify method which will be called on a service object
```yaml
unsafe:
  create:
    data:
      location:
        doc: The area the DRD is currently in
        href: http://alps.io/schema.org/Text
        field_type: select
        options:
          external:
            source: location_source
```
* Define method `location_source` on a service object
```ruby
class ServiceObject
  include Crichton::Representor::State
  represents :drd

  #...

  def location_source
    { 'list' => %w(Nibiru Kronos Vulcan) }
    #{ 'hash' => { planet1: 'Nibiru', planet2: 'Kronos', planet3: 'Vulcan' } }
  end 
end
```

It is also possible to represent a list of items as hash object and decorate it with some additional data. In such
scenario, `location_source` method is represented as lambda:

```ruby
class ServiceObject
  include Crichton::Representor::Factory
  represents :drds

  #...

  def value
    drds_collection = {
      total_count: @items.count,
      items: @items,
      location_source: ->(options) { { 'list' => %w(Nibiru Kronos Vulcan) } }
    }
    build_state_representor(drds_collection, :drds, {state: :collection})
  end
end
```

And then, in a controller:

```ruby
class DRDsController
  respond_to(:hale_json, :hal_json, :html)
  
  def index
    drds = ServiceObject.new(DRD.all, self)
    respond_with(drds.value)
  end
end
```

## Related Topics
- [Back to API Descriptor Documents](api_descriptor_documents.md)
- [Example API Descriptor Document][]

[Protocol Descriptors]: protocol_and_route_descriptors.md#protocol-descriptors
[ALPS]: http://alps.io/spec/index.html
[Example API Descriptor Document]: ../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
[Code Examples]: ../README.md#specifying-select-lists
[Service Objects]: ../README.md#service-objects
