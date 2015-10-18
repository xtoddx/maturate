# Add version behaviors to a controller that +extend+s this module.
#
# If you have an API-only rails 4 application,
# you'll want to extend +ApplicationController+ with this module.
#
# Example:
#     class ApplicationController < ActionController::Base
#       extend Maturate
#       self.api_versions = ['alpha', 'beta', 'gamma']
#
#       # by default the current_api_version would be the last in the list
#       # but maybe that is in pre-release status
#       self.current_api_version = 'beta'
#     end
#
# === Routing
#
# Maturate requires the api_version parameter to be set.
# Putting the api_version in the route is a good interface for clients
# and makes it easy to manage your versions through the routes file.
#
# Example:
#   scope '/api' do
#     scope '/:api_version' do
#       # ...
#     end
#   end
#
# This method means keeping all endpoints from all your api versions
# defined in the scope.
# You can return 404 from your controllers based on +api_version+ to
# manage endpoints that are not in particular versions of the API.
#
#   class HumansController
#     def index
#       four_oh_four if api_version != 'alpha'
#       @resources = Human.all
#     end
#
#     private
#
#     def four_oh_four
#       render text: 'Page Not Found', status: 404
#     end
#   end
#
# You could also be more explicit in your route file:
#
#   namespace '/api' do
#     namespace '/alpha', defaults: {api_version: 'alpha'} do
#       # ....
#     end
#
#     namespace '/gamma', defaults {api_version: 'gamma'} do
#       # ...
#     end
#
#     # The for the current api should still be parametrized,
#     # so +current+ and invalid versions will match.
#     namespace '/:api_version' do
#       # ...
#     end
#   end
#
# You can also use lambdas to share routes, if that makes sense for you:
#
#   shared_routes = lambda do
#     resources :humans, only: [:show]
#   end
#
#   namespace '/alpha', defaults: {api_version: 'alpha'} do
#     shared_routes.call
#     # more routes just in alpha...
#   end
#
#   # if the namespace *only* has the common routes
#   namespace '/gamma', defaults: {api_version: 'gamma'}, &shared_routes
#
# === Views and Variants
#
# It adds a +before_action+ that will set +request.variant+
# to the current api version.
# This allows you to create different view files
# for different versions of your api,
# but allows you to use the same controller action to serve all versions.
#
# For example,
# given API versions "1.0", "1.1", and "2.0" that all serve the same Human
# resource,
# you can have files "humans/index.json+1.0.jbuilder",
# "humans/index.html+1.1.jbuilder", and "humans/index.json.jbuilder",
# where the first two revisions are explictily served their correct variant
# (as denoted by "+1.x" in the file name)
# and the 2.0 API is served by the less explicit view file with no variant.
#
# Rails introduced variants to deal with different clients,
# eg render a tablet or phone optimized view for content.
# In the case of an API you don't want to discriminate against types
# of user-agents,
# so the only variant you would reasonably introduce is based on versioning.
#
# === Controllers
#
# If you have one controller that serves many versions of the API,
# you may want to add some +includes+ or other methods to your query scopes.
#
#   def show
#     @resoruces = Humans.all
#     if api_version == 'gamma'
#       @resources.includes(:compensation_packages)
#     end
#   end
#
# If the methods diverge by a large amount:
#
#   def show
#     if api_version == 'gamma'
#       show_gamma
#     else
#       show_legacy
#     end
#   end
#
#   private
#
#   def show_legacy
#   end
#
#   def show_gamma
#   end
#
# Or, if the available actions in a controller greatly diverge between versions
# you can stick a version's controllers in their own namespace,
# a la Versionist.
#
#   # config/routes.rb
#   namespace '/alpha', defaults: {api_version: 'alpha'} do
#     resources :humans, controller: AlphaVersion::Humans
#   end
#
module Maturate

  class InvalidVersion < StandardError ; end

  def self.extended kls
    kls.send :include, InstanceMethods
    setup_api_versioning kls
    setup_request_handling kls
  end

  def api_versions= ary
    @@api_versions = ary
  end

  def current_api_version= str
    unless @@api_versions.include?(str)
      msg = "#{str} is not a known version. Known: #{api_versions}. " +
            "Use `self.api_versions = [...]` to set known versions."
      raise InvalidVersion, msg
    end
    @@current_api_version = str
  end

  private

  def self.setup_api_versioning kls
    kls.send :mattr_reader, :api_versions
    @@api_versions = []
    kls.send :mattr_reader, :current_api_version
    kls.helper_method :api_version
  end

  def self.setup_request_handling kls
    kls.before_action :set_api_version_variant
    kls.before_action :set_api_default_url_param
    kls.after_action :reset_url_versioning
  end

  module InstanceMethods
    # Instance-level shortcut for a class-level accessor
    def api_versions
      self.class.api_versions
    end

    # The api version of the current request
    def api_version
      version = params[:api_version]
      return current_api_version if version == 'current'
      api_versions.include?(version) ? version : current_api_version
    end

    # Don't add api_version to the default url params.
    # Do this in a before_action call:
    # Example:
    #     class HumansController < ApplicationController
    #       before_action :skip_versioned_url_generation, only: :show
    #
    #       def show
    #         render location: unversioned_human_path(Human.first)
    #       end
    #     end
    def skip_versioned_url_generation
      @_skip_versioned_url_generation = true
    end

    private

    def set_api_version_variant
      request.variant = api_version.to_sym
    end

    def set_api_version_default_url_param
      return if @_skip_versioned_url_generation
      params = {api_version: api_version}
      self.default_url_options = default_url_options.merge(params)
    end

    def reset_url_versioning
      @_skip_versioned_url_generation = false
    end
  end
end
