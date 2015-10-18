# Maturate

Naturally grow your rails API through sane versioning.

## Is it any good?

Yes.

## Why is it good?

I've seen [versionist][versionist] used to version rails APIs in the wild.
I think the pathway of copying an entire application to create a new version
borders insanity.
The most illustrative case of this is when the difference between v2 and v3
of an API is the addition of a new resource,
with no changes to the existing resouces.
With versionist you would re-implement all existing resources in v3 api
in addition adding a new one (including new tests, etc).

Your SLOC goes up dramatically with each version if you follow the
route of duplicating your entire application.
That means each bug, defect, security hole and other nasty defect that
is yet to be discovered in your code has now dug in deeper.
It means your test suite will *never* run in a reasonable amount of time.
It means that if you refactor a public method on a model
you have to address its upstream callers repeatedly,
even though they differ only by a namespace.

The mitigation strategies for sharing some behaviors between the versions
aren't really improvements.
The most common is to create a Module in app/controllers/concerns that
encapsulates some baseline functionality to be shared between the controllers
in the different versions' namespaces.
Ruby modules are a tool for defining behaviors.
Using modules to isolate code for architectural reasons is an anti-pattern.
Each controller is spliced together from one or more concerns,
its overrides to the methods exposed by the concerns,
and the additional functionality the contoller provides for its particular
version.

The dead weight you carry between v1 and v2 may seem small.
When you reach v5 you will be crying yourself to sleep each night.

Instead of making our future-selves unhappy we want to:
* make explicit changes between versions with minimal code
* be able to enumerate and easily discover differences between versions
* make the change in the most appropraite place: view, controller, route, etc
  without effecting the others
* not fight a broken inheritance pattern: know exactly how your components are
  coupled
* reduce copy-pasting of code
* not replay the same change/refactor over-and-over when once will suffice

## Don't build apps that resist refacoring.

Just don't do it. Ever.

## How Maturate provides better options

The actual implementation notes are wrtten as RDoc in `lib/maturate.rb`.
Please browse there as well.

#### Tiny footprtint

Maturate is very small.
You can read the entire codebase in less time than it took to reach this point
in the README.
You can understand its plain ruby (with a few rails helpers) very quikcly.
You can implment it in your project in short order.

#### View-only changes

Adding, removing, or renaming fields in your responses is a common change
in APIs between versions.
This change can be made in Maturate by only creating a new view file.

users/show.json+v1.jbuilder

    json.extract @user, :id
    json.handle @user.nickname

users/show.json.jbuilder

    json.extract @user, :id, :nickname

In this case,
v1 of the API has its own explit response, and every other version will use
the file without a version specification in the filename.
This is achieved using rails' variants,
which allows us to serve different content to a particular client.

You can also check the api version in use through a helper method.

users/show.json.jbuilder

    json.extract @user, :id
    if api_version == 'v1'
      json.handle @user.nickname
    else
      json.extract @user, :nickname
    end

#### Controller-only changes

If v2 of the API only returns active records,
but v1 returns records of any state,
we can implement that change quickly!

auctions_controller.rb

    def index
      @records = Auctions.all
      unless api_version == 'v1'
        @records = @records.where(status: 'active')
      end
    end

## How it works

#### Defining API verions

You,
as the app's maintainer,
will specify the API versions the application will respond to.

application_controller.rb

    class ApplicationController < ActionControler::Base
      extend Maturate
      self.api_versions = ['v1', 'v2']
    end

You will expose those versions to clients through the urls used to access
your application.

config/routes.rb

    scope '/:api_version' do
      resources :auctions
    end

As long as an `api_version` parameter is specificed,
Maturate will work as expected.
This includes automatically building links using rails' route helpers
(eg: `auctions_path`)
without explictly specifying the version in the call to the helper.

The symbolic `current` version is defined as well.
In the default case it will point to the last element of the versions
array provided to `self.api_versions=` in your controller class.
You can explictly set the current version,
which can be useful if you have a pre-release version in the list,
but you aren't ready to ship it as the default yet.

application_controler.rb

    self.current_api_version = 'v1'

Version requests that don't match a known version number will match `current`.

#### Using variants for view selection

Rails introduced the capability to serve views to different clients using
a system called "variants."
Originally intended to show different views for phones, tables, and desktops,
it makes perfect sense to use for api versioning.
In the API world we don't show preference to the user-agent,
but our outputs will be varied based on the data specification used for a
particular version of the API.

All you need to do to take advantage of variants is to name your view files
according to a pattern.
The rails naming convention for variant-capable view files is
`action.mime+variant.renderer`.
An example might be `show.json+v1.jbuilder`.

If there is no match for a particular variant,
the standard view file of `action.mime.renderer` will be used.

#### Overriding URL auto-versioning

It may come up in your project that you want to link to an unversioned
resource,
or to a different version of the api.

In this case you can explictly set `api_version: nil` or `api_version: 'v1'`
in your route helper.
You can stop the api_version parameter from being added by urls by default
using the `skip_versioned_url_generation` class-level method in a controller.

auctions_controller.rb

    class AuctionsController
      skip_versioned_url_generation only: [:post_pament]

      def post_payment
        # invoices are documents that don't have a versioned api,
        # you just get to download them directly.
        @invoice_url = invoice_url(auction.invoice)
      end

      def review
        @invoice_url = invoice_url(auction.invoice, api_version: nil)
      end
    end

## Help Welcomed

Please contribute!

I'm not interested in adding features like HTTP-header based version
specification,
or other goofy things that make life harder on clients.
I'm not interested in offering bells, whistles, or trying to keep pace
with other libraries.

I am interested in maintaing the leanest versioning solution for rails.

I'm especially interested in working with the rails 5 api changes,
so if you have knowledge about how the API-only controllers in rails 5 work,
please get in touch and lets make fun things.

#### Flow

This is how I test and build the gem.

    docker build --tag=maturate .
    docker run -it --rm -v $PWD:/usr/src/app maturate rake
    docker run -it --rm -v $PWD:/usr/src/app maturate gem build maturate.gemspec




[versionist]: https://rubygems.org/gems/versionist
