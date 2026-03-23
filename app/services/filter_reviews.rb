class FilterReviews
  SORT_FIELDS = {
    "rating" => :rating,
    "created_at" => :created_at,
    "updated_at" => :updated_at
  }.freeze

  ORDER_DIRECTIONS = %w[asc desc].freeze

  def initialize(reviewable, sort_by, order, description_only, rating)
    @reviewable = reviewable
    @sort_by = sort_by
    @order = order
    @description_only = description_only
    @rating = rating
  end

  def run
    @reviews = @reviewable.reviews

    description_reviews if description_only?
    rating_filter
    sort_reviews

    @reviews
  end

  private

  def description_only?
    ActiveModel::Type::Boolean.new.cast(@description_only)
  end

  def description_reviews
    @reviews = @reviews.descriptive_only
  end

  def rating_filter
    return unless @rating.present?

    rating_int = Integer(@rating)
    return unless rating_int.between?(1, 5)

    @reviews = @reviews.where(rating: rating_int)
  rescue ArgumentError
    # Ignore invalid input; sorting/filtering should never introduce SQL injection.
    nil
  end

  def sort_reviews
    return if @sort_by.blank?

    sort_column = SORT_FIELDS[@sort_by.to_s]
    return unless sort_column

    direction =
      ORDER_DIRECTIONS.include?(@order.to_s.downcase) ? @order.to_s.downcase : "asc"

    # Use a whitelist + hash ordering to avoid SQL injection.
    @reviews = @reviews.order(sort_column => direction)
  end
end
