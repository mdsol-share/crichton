# @title Know Your Options

# Overview
When rendering a response, there are a number of options that can be used in context of a request in a controller to
modify the response rendered by Crichton. The following describes the different options Crichton understands:

* `:conditions` - The list of conditions applicable to the request that Crichton uses to filter available links.
* `:except` - Data descriptor names to filter out from the response data.
* `:only` - Data descriptor names to limit the response data to.
* `:include` - Embedded resource descriptor names to include in the response.
* `:exclude` - Embedded resource descriptor names to exclude from the response.
* `:embed_optional` - Controls whether optionally embeddable links and resources, as defined in 
[_API Descriptor Document_][] are returned in the response.
* `:additional_links` - Allows dynamically adding new links to the top-level resource.
* `:override_links` - Allow overriding the URL set in defined links.
* `:state` - The state of the resource, which can be used to set or override the state of the resource.

Options will typically be determined based on some request params/context/permission logic or 
[Service Object][] in a controller to dynamically modify the response. 

## Rails Code Example

```ruby
def show
  @drd = Drd.find_by_uuid(params[:id])
  respond_with(@drd, { conditions: [:can_do_anything], additional_links: { 'next' => '...' } })
end
```

## Other Frameworks Code Example

```ruby
def show
  @drd = Drd.find_by_uuid(params[:id])
  @drd.to_media_type(:hale_json, { conditions: [:can_do_anything], additional_links: { 'next' => '...' } })
end
```

## Conditions Examples


[Service Object]: ../README.md#service-objects
