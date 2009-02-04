require File.dirname(__FILE__) + '/../test_helper'
require 'enzyme_coverage_controller'

# Re-raise errors caught by the controller.
class EnzymeCoverageController; def rescue_action(e) raise e end; end

class EnzymeCoverageControllerTest < Test::Unit::TestCase
  def setup
    @controller = EnzymeCoverageController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
