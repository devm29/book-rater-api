class Review < ApplicationRecord
  PROFANITY_WORDS = %w[frak storms gorram nerfherder crivens].freeze
  PROFANITY_REGEX = Regexp.new("\\b(?:#{PROFANITY_WORDS.join('|')})\\b", Regexp::IGNORECASE).freeze

  belongs_to :reviewable, polymorphic: true
  belongs_to :user

  validates :rating, presence: true, inclusion: { in: 1..5, message: 'rating should be in range of 1..5' }
  validates :reviewable_id, uniqueness: { scope: %i[reviewable_type user_id], message: "can't post multiple reviews" }
  validates :description, length: { maximum: 300 }, allow_nil: true

  before_validation :normalize_description

  validate :fictional_profanity

  after_create :reviewable_rating

  scope :descriptive_only, -> { where.not(description: [nil, '']) }

  private

  def fictional_profanity
    return if description.blank?
    return unless description.match?(PROFANITY_REGEX)

    errors.add(:description, 'cannot contain fictional profanity')
  end

  def normalize_description
    return if description.nil?

    self.description = description.strip
    self.description = nil if self.description.blank?
  end

  def reviewable_rating
    # NOTE: It was asked to calculate average rating for books only. Therefore I have added a check for books
    # TODO: We can add rating column for author as well just like books
    return unless reviewable_type == "Book"

    reviews_count = reviewable.reviews.count
    pre_rating = reviewable.rating || 0

    pre_score = pre_rating * (reviews_count - 1)
    new_score = pre_score + rating.to_d

    updated_rating = new_score / reviews_count
    reviewable.update!(rating: updated_rating)
  end
end
