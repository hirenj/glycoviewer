require File.dirname(__FILE__) + '/../test_helper'
require 'structure_map_controller'

# Re-raise errors caught by the controller.
class StructureMapController; def rescue_action(e) raise e end; end

class StructureMapControllerTest < Test::Unit::TestCase
  def setup
    @controller = StructureMapController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_garbage_collection
    assert_equal(0, ObjectSpace.each_object(Monosaccharide) {})
    assert_equal(0, ObjectSpace.each_object(Linkage) {})    
    assert_equal(0, ObjectSpace.each_object(Sugar) {})
    get :show, { :ids => [43,42] }
    ObjectSpace.garbage_collect    
    assert_equal(0, ObjectSpace.each_object(Monosaccharide) {})
    assert_equal(0, ObjectSpace.each_object(Linkage) {})    
  end
end
