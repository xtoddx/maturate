require 'test_helper'

class MaturateTest < ActiveSupport::TestCase
  setup do
    @controller = Class.new(ActionController::Base) { extend Maturate }
  end

  test 'can set api version on controller' do
    assert @controller.respond_to?(:api_versions=)
  end

  test 'api versions are readable' do
    @controller.api_versions = ['a', 'b']
    assert_equal ['a', 'b'], @controller.api_versions
  end

  test 'can set current_api_version to a known version' do
    @controller.api_versions = ['a', 'b']
    assert_send [@controller, :current_api_version=, 'b']
  end

  test 'cannot set current_api_version to an unknown version' do
    @controller.api_versions = ['a', 'b']
    assert_raises(Maturate::InvalidVersion) do
      @controller.current_api_version = 'c'
    end
  end
end

class MaturateRequestTest < ActionController::TestCase
  tests HumansController

  test 'api_version set by request' do
    get :index, api_version: 'v1'
    assert_equal [:v1], request.variant
  end

  test 'current symbolic-version maps to latest' do
    get :index, api_version: 'curent'
    assert_equal [:v2], request.variant
  end

  test 'unknown version maps to latest' do
    get :index, api_version: '?????????'
    assert_equal [:v2], request.variant
  end

  test 'latest version can be set manually' do
    begin
      ApplicationController.current_api_version = 'v1'
      get :index, api_version: 'current'
      assert_equal [:v1], request.variant
    ensure
      ApplicationController._current_api_version = nil
    end
  end

  test 'url generation includes api_version by default' do
    get :index, api_version: 'v1'
    assert_equal '/api/v1/humans', response.headers['Location']
  end

  test 'url version param can be disabled' do
    get :index2, api_version: 'v1'
    assert_equal '/not-api/benefits_packages', response.headers['Location']
  end
end
