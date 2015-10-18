require 'test_helper'

class MaturateTest < ActiveSupport::TestCase
  setup do
    @controller = Class.new(ActionController::Base) { extend Maturate }
  end

  test 'can set api version on controller' do
    assert @controller.respond_to?(:api_versions=)
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
