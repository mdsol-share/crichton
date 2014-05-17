# @title Serialization
# Overview
To use the serialization functionality, you need to call the serializer. If you are working in Rails, the serializer is automatically registered with the Rails MIME-type mechanism.
You can also call the serializer manually by calling `object.to_media_type(:xhtml, {})`. 
In this call the first argument is the media type. Currently, `:xhtml` and `:html` are registered, but other media types are expected). The second argument is the options hash.

## Options Hash

The options hash can contain the following values:

- `conditions: [:condition]`
  Conditions are defined in the States section of the descriptor document. See the [Resource Descriptors][resource_descriptors.md] document for more information about conditions.
- `semantics: :styled_microdata`
  The semantics option indicates the semantic mark-up type to apply to the resource. Valid options include: `:microdata` and `:styled_microdata`. 
  If you not include semantics, Crichton defaults to `:microdata`.
- `embed_optional: {'name1' => :embed, 'name2' => :link}`
  The keys need to be strings that correspond to the name of the attribute that has an `embed: single-optional`,
`multiple-optional`,`single-optional-link`, or `multiple-optional-link`.
  The first two embed values - those without `-link` - default to `:embed` when you specify no `embed_optional` parameter. The embed values `-link` default to embedding a link.

## Rails Code Example
A Rails example of serialization appears below.

NOTE: The options hash typically generates elsewhere. For the sake of the example, it appears in the `respond_with` call.

```ruby
  def show
    @drd = Drd.find_by_uuid(params[:id])
    respond_with(@drd, {conditions: :can_do_anything, embed_optional: {'items' => :link})
  end
```
