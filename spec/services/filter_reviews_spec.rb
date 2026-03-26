require "rails_helper"

RSpec.describe FilterReviews do
  let(:book) { create(:book) }
  let(:user_1) { create(:user) }
  let(:user_2) { create(:user) }
  let(:user_3) { create(:user) }

  def create_review(user:, rating:, description:)
    create(
      :review,
      reviewable: book,
      user: user,
      rating: rating,
      description: description
    )
  end

  describe "#run" do
    it "filters reviews to only those with descriptions when description_only is truthy" do
      create_review(user: user_1, rating: 3, description: nil)
      create_review(user: user_2, rating: 4, description: "")
      descriptive = create_review(user: user_3, rating: 5, description: "Great book")

      service = described_class.new(book, nil, nil, "true", nil)
      results = service.run

      expect(results).to contain_exactly(descriptive)
    end

    it "filters by exact rating when rating filter is provided" do
      create_review(user: user_1, rating: 2, description: "Bad")
      create_review(user: user_2, rating: 4, description: "Okay")
      create_review(user: user_3, rating: 4, description: "Good")

      service = described_class.new(book, nil, nil, nil, 4)
      results = service.run

      expect(results.pluck(:rating)).to all(eq(4))
      expect(results.count).to eq(2)
    end

    it "sorts safely by whitelisted columns" do
      create_review(user: user_1, rating: 2, description: "Low")
      create_review(user: user_2, rating: 5, description: "High")
      create_review(user: user_3, rating: 3, description: "Mid")

      service = described_class.new(book, "rating", "desc", nil, nil)
      results = service.run.to_a

      expect(results.map(&:rating)).to eq([5, 3, 2])
    end

    it "defaults to ascending order for invalid order directions" do
      create_review(user: user_1, rating: 1, description: "One")
      create_review(user: user_2, rating: 5, description: "Five")

      service = described_class.new(book, "rating", "DESC;DROP TABLE reviews", nil, nil)
      results = service.run.to_a

      expect(results.map(&:rating)).to eq([1, 5])
    end

    it "does not apply sorting when sort_by is not whitelisted (SQL injection safe)" do
      r1 = create_review(user: user_1, rating: 1, description: "One")
      r2 = create_review(user: user_2, rating: 5, description: "Five")

      service = described_class.new(book, "rating); DROP TABLE reviews; --", "desc", nil, nil)

      # Without a whitelisted sort column, results should be the same record set
      # as the underlying association scope.
      expect(service.run.pluck(:id)).to match_array(book.reviews.pluck(:id))
      expect(service.run.pluck(:id)).to match_array([r1.id, r2.id])
    end
  end
end

