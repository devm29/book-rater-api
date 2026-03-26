RSpec.describe '/api/books and authors reviews' do
  let(:response_hash) { JSON(response.body, symbolize_names: true) }

  describe 'GET to /' do
    it 'returns all books' do
      review = create(:review)

      get api_book_reviews_path(review.reviewable_id)

      expect(response_hash).to eq(
        {
          reviews: [
            {
              created_at: review.created_at.iso8601(3),
              description: review.description,
              id: review.id,
              rating: review.rating,
              reviewable_id: review.reviewable_id,
              reviewable_type: review.reviewable_type,
              updated_at: review.updated_at.iso8601(3),
              user_id: review.user_id
            }
          ]
        }
      )
    end
  end

  describe 'GET filtering and sorting' do
    it 'supports description_only=true' do
      book = create(:book)
      user_with_description = create(:user)
      user_without_description = create(:user)

      review_with_description = create(
        :review,
        reviewable: book,
        user: user_with_description,
        rating: 5,
        description: "Great book"
      )

      create(
        :review,
        reviewable: book,
        user: user_without_description,
        rating: 4,
        description: ""
      )

      get api_book_reviews_path(book.id, params: { description_only: true })

      expect(response_hash[:reviews].map { |r| r[:id] }).to eq([review_with_description.id])
    end

    it 'supports rating filtering' do
      book = create(:book)
      create(
        :review,
        reviewable: book,
        user: user_1 = create(:user),
        rating: 3,
        description: "Ok"
      )
      review_4a = create(
        :review,
        reviewable: book,
        user: user_2 = create(:user),
        rating: 4,
        description: "Good"
      )
      review_4b = create(
        :review,
        reviewable: book,
        user: user_3 = create(:user),
        rating: 4,
        description: "Great"
      )

      get api_book_reviews_path(book.id, params: { rating: 4 })

      expect(response_hash[:reviews].map { |r| r[:id] }).to match_array([review_4a.id, review_4b.id])
    end

    it 'supports sorting by rating desc' do
      book = create(:book)
      u1 = create(:user)
      u2 = create(:user)
      u3 = create(:user)

      r2 = create(:review, reviewable: book, user: u1, rating: 2, description: "Low")
      r5 = create(:review, reviewable: book, user: u2, rating: 5, description: "High")
      r3 = create(:review, reviewable: book, user: u3, rating: 3, description: "Mid")

      get api_book_reviews_path(book.id, params: { sort_by: "rating", order: "desc" })

      expect(response_hash[:reviews].map { |r| r[:id] }).to eq([r5.id, r3.id, r2.id])
    end
  end

  describe 'POST to /' do
    context 'when successful' do
      let(:user) { create(:user) }
      let(:book) { create(:book) }
      let(:params) do
        {
          rating: 4,
          description: 'It was the best of times',
          user_id: user.id
        }
      end

      it 'creates a review' do
        expect { post api_book_reviews_path(book.id, params: params) }.to change { Review.count }
      end

      it 'returns the success message' do
        post api_book_reviews_path(book.id), params: params

        expect(response_hash).to eq({message: "success"})
      end
    end

    context 'when description is empty' do
      let(:user) { create(:user) }
      let(:book) { create(:book) }
      let(:params) do
        {
          rating: 4,
          description: "",
          user_id: user.id
        }
      end

      it 'creates the review but treats it as no description' do
        expect { post api_book_reviews_path(book.id), params: params }.to change { Review.count }.by(1)

        get api_book_reviews_path(book.id, params: { description_only: true })
        expect(response_hash[:reviews]).to be_empty
      end
    end

    context 'when profanity is provided' do
      let(:user) { create(:user) }
      let(:book) { create(:book) }
      let(:params) do
        {
          rating: 4,
          description: "Frak",
          user_id: user.id
        }
      end

      it 'returns a descriptive error' do
        post api_book_reviews_path(book.id), params: params

        expect(response_hash).to eq(
          {
            errors: ["Description cannot contain fictional profanity"]
          }
        )
      end
    end

    context 'when the user already reviewed the book' do
      let(:user) { create(:user) }
      let(:book) { create(:book) }

      let!(:existing_review) do
        create(:review, reviewable: book, user: user, rating: 3, description: "Nice")
      end

      it 'returns uniqueness validation error' do
        params = {
          rating: 4,
          description: "Another",
          user_id: user.id
        }

        expect { post api_book_reviews_path(book.id), params: params }.not_to change { Review.count }

        expect(response_hash[:errors].join(" ")).to include("can't post multiple reviews")
      end
    end

    context 'when unsuccessful' do
      let(:user) { create(:user) }
      let(:book) { create(:book) }
      let(:params) do
        {
          rating: 7,
          description: 'It was the best of times',
          user_id: user.id
        }
      end

      it 'returns an error' do
        post api_book_reviews_path(book.id), params: params

        expect(response_hash).to eq(
          {
            errors: ['Rating rating should be in range of 1..5']
          }
        )
      end
    end
  end

  describe "Authors reviews endpoint" do
    it "returns all reviews for an author" do
      author = create(:author)
      user_1 = create(:user)
      user_2 = create(:user)

      review_1 = create(:review, reviewable: author, user: user_1, rating: 5, description: "Great")
      review_2 = create(:review, reviewable: author, user: user_2, rating: 4, description: "Good")

      get api_author_reviews_path(author.id)

      expect(response_hash[:reviews].map { |r| r[:id] }).to match_array([review_1.id, review_2.id])
    end

    it "supports description_only=true for author reviews" do
      author = create(:author)
      user_1 = create(:user)
      user_2 = create(:user)

      review_with_description = create(:review, reviewable: author, user: user_1, rating: 5, description: "Great")
      create(:review, reviewable: author, user: user_2, rating: 4, description: "")

      get api_author_reviews_path(author.id, params: { description_only: true })

      expect(response_hash[:reviews].map { |r| r[:id] }).to eq([review_with_description.id])
    end
  end
end
