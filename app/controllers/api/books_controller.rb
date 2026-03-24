module API
  class BooksController < ApplicationController
    def create
      book = Book.new(allowed_params)

      if book.save
        render json: book, status: :created
      else
        render_errors(book)
      end
    end

    def index
      render json: Book.all, status: :ok
    end

    def show
      render json: Book.find(params[:id]), status: :ok
    end

    def update
      book = Book.find(params[:id])

      if book.update(allowed_params)
        render json: book, status: :ok
      else
        render_errors(book)
      end
    end

    private

    def allowed_params
      params.permit(
        :author_id,
        :description,
        :publish_date,
        :rating,
        :title
      )
    end
  end
end