require File.dirname(__FILE__) + '/../test_helper'
require 'sviewer_controller'

# Re-raise errors caught by the controller.
class SviewerController; def rescue_action(e) raise e end; end

class SviewerControllerTest < Test::Unit::TestCase
  def setup
    @controller = SviewerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_garbage_collection
    assert_equal(0, ObjectSpace.each_object(Monosaccharide) {})
    assert_equal(0, ObjectSpace.each_object(Linkage) {})    
    assert_equal(0, ObjectSpace.each_object(Sugar) {})
    get :index, { :seq => 'D-Galp(b1-4)D-Galp' }
    ObjectSpace.garbage_collect    
    assert_equal(0, ObjectSpace.each_object(Monosaccharide) {})
    assert_equal(0, ObjectSpace.each_object(Linkage) {})    
  end
end
