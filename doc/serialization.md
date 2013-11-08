# @title Serialization
# Overview
In order to use the serialization functionality, you need to call the serializer.
If you are working in a Rails context, the serializer gets automatically registered with the Rails MIME type mechanism.
You can also call the serializer manually - by calling `object.to_media_type(:xhtml, {})`. The first argument is the
media type (currently, `:xhtml` and `:html` are registered, but other media types are expected) and the second argument
is the options hash.

# Options hash

The options hash may contain:

## `conditions: [:condition]`

The conditions are defined in the states section of the descriptor document. See the
  [state descriptors documentation][doc/state_descriptors.md] for more information on that topic.

## `semantics: :styled_microdata`

Semantics indicates the semantic markup type to apply. Valid options are
`:microdata` and `:styled_microdata`. If not included, defaults to `:microdata`.

## `embed_optional: {'name1' => :embed, 'name2' => :link}`

The keys need to be strings which correspond to the name of the attribute that has an `embed: single-optional`
or `multiple-optional` or `single-optional-link` or `multiple-optional-link`. The first two embed values (the ones
without `-link`) default to `:embed` when no `embed_optional` parameter is specified, the ones with `-link` default
to embedding a link.

# Rails example
```ruby
  def show
    @drd = Drd.find_by_uuid(params[:id])
    respond_with(@drd, {conditions: :can_do_anything, embed_optional: {'items' => :link})
  end
```

The options hash will typically be generated elsewhere, but for the sake of the example it is in the respond_with call.

