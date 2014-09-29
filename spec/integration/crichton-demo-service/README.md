# Overview
This demo service is a vanilla implementation of a Rails application using [Crichton][]. It exposes several resources 
representing Diagnostic Repair Drones (DRDs). 

The demo service uses a sample [_API Descriptor Document_][] in Crichton, which describes a simple state machine with
conditions on the various transitions. These conditions would typically be determined in the context of a request
and passed in as options in the response. It further describes the semantics of the resources and the protocol-specific 
implementations used to generate the responses. 

In order to explore Crichton's runtime generation of available transitions based on both the state of resources and the 
satisfied conditions, a `condition` query parameter can be added in the browser to mimic this on the fly, as discussed 
in the examples below.


## Setup

```
$ bundle install
$ rake setup
$ bundle exec rails s -p 3000
```

Note:  In some instances, it may be necessary to run `bundle update` to update the crichton gem with the latest 
version since it currently points to a Github branch.

## Exploring
Take a look at the controllers and models to see the basic implementation for both single entities and resources that
embed other resources with meta-data.

### Surfing the API in a browser
Crichton supports the media type `text/html` which allows interacting with an API directly in a browser. Enter the API 
by opening `http://localhost:3000` in a browser and and follow your nose. You will find a list of available resource 
entry points. 

Click a URL link to navigate to the associated entry point. You can add the following conditions, either as a single 
value or comma-separated list at any time, to see what changes when interacting with a resource:

* can_do_anything
* can_create
* can_update
* can_delete
* can_activate
* can_deactivate
* airlock_open

E.g. `http://localhost:3000/drds?conditions=can_delete,can_activate`

### Curl
Crichton also supports a number of media-types out of the box. You can explore these [supported media types][] using 
curl:

```
$ curl --header "Accept: application/vnd.hale+json" GET http://localhost:3000/drds
```

You can add the conditions query parameter here as well.

```
$ curl --header "Accept: application/vnd.hale+json" GET http://localhost:3000/drds?conditions=airlock_open
```

### ALPS
Don't miss the [ALPS][] profile link when you view source in the head tag for responses and as a "Rel" link at the 
`localhost:3000` root. This profile (`http://localhost:3000/alps/DRDs`) is generated from the associated resource 
descriptor in the [_API Descriptor Document_] and represents all the  semantics and affordances that you will find in a 
response.

## Default Rails HTML template responses
You will notice there are no view templates defined to support the HTML and XHTML media-types. If you are wondering 
what happens if I include an HTML view, change the name of the [index.html.orb](app/views/drds/index.html.orb) file to 
`index.html.erb` and then reload the URL `http://localhost:3000/drds`.

Hint: It works like it should.

[Crichton]: https://github.com/mdsol/crichton/tree/0.0.1
[_API Descriptor Document_]: https://github.com/mdsol/crichton/blob/0.0.1/spec/fixtures/resource_descriptors/drds_descriptor_v1.yml
[supported media types]: https://github.com/mdsol/crichton/tree/0.0.1#supported-media-types
[ALPS]: http://alps.io/spec/index.html
