require "spec_helper"

describe GeneralUtils do
	include GeneralUtils
	describe "#get_user_id" do
		it "returns an existing user id from the session" do
			@session = {}
			@session[:user_id] = "Diamond"
			expect(get_user_id(@session)).to eq("Diamond")
		end

		it "returns a nil user id from the session" do
			@session = {}
			expect(get_user_id(@session)).to eq(nil)
		end
	end

	describe "#is_user_logged_in" do
		it "returns true if the user_id is not nil" do
			expect(is_user_logged_in(nil)).to be false
		end

		it "returns false if the user_id is nil" do
			expect(is_user_logged_in("user_id")).to be true
		end
	end
end
