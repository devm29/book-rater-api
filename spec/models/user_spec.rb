require "rails_helper"

RSpec.describe User, type: :model do
  it "validates presence of first_name" do
    user = build(:user, first_name: nil)
    user.valid?

    expect(user.errors[:first_name]).to be_present
  end

  it "validates presence of last_name" do
    user = build(:user, last_name: nil)
    user.valid?

    expect(user.errors[:last_name]).to be_present
  end
end

