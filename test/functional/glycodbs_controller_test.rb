require 'test_helper'

class GlycodbsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:glycodbs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create glycodb" do
    assert_difference('Glycodb.count') do
      post :create, :glycodb => { }
    end

    assert_redirected_to glycodb_path(assigns(:glycodb))
  end

  test "should show glycodb" do
    get :show, :id => glycodbs(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => glycodbs(:one).id
    assert_response :success
  end

  test "should update glycodb" do
    put :update, :id => glycodbs(:one).id, :glycodb => { }
    assert_redirected_to glycodb_path(assigns(:glycodb))
  end

  test "should destroy glycodb" do
    assert_difference('Glycodb.count', -1) do
      delete :destroy, :id => glycodbs(:one).id
    end

    assert_redirected_to glycodbs_path
  end
end
