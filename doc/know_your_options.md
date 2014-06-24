# @title Know Your Options

## Overview
When responding to a request, there are a number of options that can be used in the context of a request in a controller 
to modify the response rendered by Crichton. Options will typically be determined based on some request 
params/context/permission logic or [Service Object][] in a controller to dynamically customize the response. 
The following examples assume a client negotiates an `application/hal+json` response.

### Code Example

```ruby
def index
  @eBooks = EBookList.all
  options =  # ...
  respond_with(@eBooks, options)
end

def show
  @ebook = EBook.find_by_uuid(params[:id])
  options = # ...
  respond_with(@ebook, options)
end
```

### eBooks Response
Baseline `index` method response with {} options specified.

```json
{
  "_links": {
    "self": { "href": "..." },
    "items": [ ... ],
    "authors": [ ... ]
  },
  "total_count": 2,
  "_embedded": {
    "items": [ ... ],
    "authors": [ ... ]
  }
}
```

### eBook Response
Baseline `show` method response with {} options specified.

```json
{
  "_links": {
    "self": { "href": "..." },
    "author": { "href": "..." }
  },
  "name": "RESTful Web APIs",
  "text": "I am going to show you a better way to do distributed computing ...",
  "status": "draft"
}
```

## Options
### :conditions
The list of conditions applicable to the request that Crichton uses to filter available links as defined in individual 
state transitions in an [_API Descriptor Document_][].

```ruby
options = { conditions: [:is_author] }
```

`eBooks`

```json
{
  "_links": {
    "self": { "href": "..." },
    "create": { "href": "..." },
    "items": [ ... ],
    "authors": [ ... ]
  },
  "total_count": 2,
  "_embedded": {
    "items": [ ... ],
    "authors": [ ... ]
  }
}
```

`eBook`

```json
{
  "_links": {
    "self": { "href": "..." },
    "edit": { "href": "..." },
    "copy": { "href": "..." },
    "release": { "href": "..." },
    "delete": { "href": "..." },
    "author": { "href": "..." }
  },
  "name": "RESTful Web APIs",
  "text": "I am going to show you a better way to do distributed computing ...",
  "status": "draft"
}
```

```ruby
options = { conditions: ['can_edit', 'can_copy'] }
```

`eBook`

```json
{
  "_links": {
    "self": { "href": "..." },
    "edit": { "href": "..." },
    "copy": { "href": "..." },
    "author": { "href": "..." }
  },
  "name": "RESTful Web APIs",
  "text": "I am going to show you a better way to do distributed computing ...",
  "status": "draft"
}
```

### :except
Data descriptor names to filter out from the response data.

```ruby
options = { except: [:text] }
```

`eBook`

```json
{
  "_links": {
    "self": { "href": "..." },
    "author": { "href": "..." }
  },
  "name": "RESTful Web APIs",
  "status": "draft"
}
```

### :only
Data descriptor names to limit the response data to.

```ruby
options = { only: ['text'] }
```

`eBook`

```json
{
  "_links": {
    "self": { "href": "..." },
    "author": { "href": "..." }
  },
  "text": "I am going to show you a better way to do distributed computing ..."
}
```

### :include
Embedded resource descriptor names to include in the response.

```ruby
options = { include: [:items] }
```

`eBooks`

```json
{
  "_links": {
    "self": { "href": "..." },
    "create": { "href": "..." },
    "items": [ ... ],
    "authors": [ ... ]
  },
  "total_count": 2,
  "_embedded": {
    "items": [ ... ]
  }
}
```

### :exclude
Embedded resource descriptor names to exclude from the response.

```ruby
options = { exclude: ['items'] }
```

`eBooks`

```json
{
  "_links": {
    "self": { "href": "..." },
    "create": { "href": "..." },
    "items": [ ... ],
    "authors": [ ... ]
  },
  "total_count": 2,
  "_embedded": {
    "authors": [ ... ]
  }
}
```

### :embed_optional
Controls whether optionally embeddable links and resources, as defined in [_API Descriptor Document_][], are returned 
in the response. For more information, see the [Data and Transition Descriptors][] `embed` property. 

```ruby
options = { embed_optional: { embed: ['author'] } }
```

`eBook`

```json
{
  "_links": {
    "self": { "href": "http://example.com/other_self" },
    "author": { "href": "..." }
  },
  "name": "RESTful Web APIs",
  "text": "I am going to show you a better way to do distributed computing ...",
  "status": "draft",
  "_embedded": {
    "author": { ... }
  }
}
```

### :additional_links
Allows dynamically adding new links to the top-level resource.

```ruby
options = { additional_links: { next: { href: 'http://example.com/next' } }
```

`eBooks`

```json
{
  "_links": {
    "self": { "href": "..." },
    "next": { "href": "http://example.com/next" },
    "items": [ ... ],
    "authors": [ ... ]
  },
  "total_count": 2,
  "_embedded": {
    "items": [ ... ],
    "authors": [ ... ]
  }
}
```

### :override_links
Allow overriding the URL set in defined links.

```ruby
options = { override_links: { 'self' => { href: 'http://example.com/other_self' } }
```

`eBook`

```json
{
  "_links": {
    "self": { "href": "http://example.com/other_self" },
    "author": { "href": "..." }
  },
  "name": "RESTful Web APIs",
  "text": "I am going to show you a better way to do distributed computing ...",
  "status": "draft"
}
```

### :state
The state of the resource, which can be used to set or override the state of the resource.

```ruby
options = { state: 'published', conditions: :is_author }
```

`eBook`

```json
{
  "_links": {
    "self": { "href": "http://example.com/other_self" },
    "author": { "href": "..." }
  },
  "name": "RESTful Web APIs",
  "text": "I am going to show you a better way to do distributed computing ...",
  "status": "draft"
}
```

[_API descriptor document_]: doc/api_descriptor_documents.md
[Service Object]: ../README.md#service-objects
[Data and Transition Descriptors]: data_and_transition_descriptors.md#data-descriptor-properties
