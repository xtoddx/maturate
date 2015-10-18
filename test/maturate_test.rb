require 'test_helper'

class MaturateTest < ActiveSupport::TestCase
  test 'can set api version on controller' do
    assert ApplicationController.respond_to?(:api_versions=)
  end
end
