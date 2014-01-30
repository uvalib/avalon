require 'spec_helper'
require 'cancan/matchers'

describe Users::OmniauthCallbacksController do
  include Devise::TestHelpers 

  describe "Logged in as LTI" do
    before :each do
      OmniAuth.config.test_mode = true 
      OmniAuth.config.add_mock(:lti, {  :provider    => "lti", 
                               :uid         => "1234", 
                               :credentials => {   :token => "lk2j3lkjasldkjflk3ljsdf"},
                               :info => { :email => "someone@somewhere.com" },
                               :extra => { :raw_info => { :context_id => "some_course_name" }}
                            })
      request.env["devise.mapping"] = Devise.mappings[:user]
      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:lti]
      post "lti"
    end

    it "should have virtual_groups" do
      expect(subject.user_session[:virtual_groups]).not_to be_empty
    end

    it "should not be a full login" do
      expect(subject.user_session[:full_login]).to be_false
    end
  end
end
