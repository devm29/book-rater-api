require "rails_helper"

RSpec.describe Review, type: :model do
  describe "validations" do
    it "requires rating in the range 1..5" do
      book = create(:book)
      user = create(:user)

      review = build(:review, reviewable: book, user: user, rating: 0, description: "Nice")

      review.valid?

      expect(review.errors[:rating]).to include("rating should be in range of 1..5")
    end

    it "validates description max length (300 chars)" do
      book = create(:book)
      user = create(:user)

      review = build(
        :review,
        reviewable: book,
        user: user,
        rating: 3,
        description: "a" * 301
      )

      review.valid?

      expect(review.errors[:description]).to include("is too long (maximum is 300 characters)")
    end
  end

  describe "description normalization" do
    it "turns whitespace-only descriptions into nil" do
      book = create(:book)
      user = create(:user)

      review = build(:review, reviewable: book, user: user, rating: 3, description: "   ")
      review.valid?

      expect(review.description).to be_nil
      expect(review).to be_valid
    end
  end

  describe "fictional profanity validation" do
    it "rejects fictional profanity case-insensitively with punctuation" do
      book = create(:book)
      user = create(:user)

      review = build(
        :review,
        reviewable: book,
        user: user,
        rating: 3,
        description: "I shouted Frak, loudly."
      )

      review.valid?

      expect(review.errors[:description]).to include("cannot contain fictional profanity")
    end

    it "allows words that only contain the profanity fragment" do
      book = create(:book)
      user = create(:user)

      review = build(
        :review,
        reviewable: book,
        user: user,
        rating: 3,
        description: "This is fraking behavior, not fraking itself."
      )

      expect(review).to be_valid
    end
  end

  describe "callbacks" do
    it "updates the average rating for books after creating a review" do
      book = create(:book, rating: nil)
      user_1 = create(:user)
      user_2 = create(:user)

      create(:review, reviewable: book, user: user_1, rating: 2, description: "Good")
      expect(book.reload.rating.to_d).to eq(2.to_d)

      create(:review, reviewable: book, user: user_2, rating: 4, description: "Great")
      expect(book.reload.rating.to_d).to eq(3.to_d)
    end
  end

  describe "uniqueness" do
    it "allows only one review per user per reviewable" do
      book = create(:book)
      user = create(:user)

      create(:review, reviewable: book, user: user, rating: 3, description: "Nice")

      duplicate = build(:review, reviewable: book, user: user, rating: 4, description: "Another")
      duplicate.valid?

      expect(duplicate).to be_invalid
      expect(duplicate.errors.full_messages.join(" ")).to include("can't post multiple reviews")
    end
  end
end

