module API
  class AuthorsController < ApplicationController
    def create
      author = Author.new(allowed_params)

      if author.save
        render json: author, status: :created
      else
        render_errors(author)
      end
    end

    def index
      render json: Author.all, status: :ok
    end

    def show
      render json: Author.find(params[:id]), status: :ok
    end

    def update
      author = Author.find(params[:id])

      if author.update(allowed_params)
        render json: author, status: :ok
      else
        render_errors(author)
      end
    end

    private

    def allowed_params
      params.permit(
        :description,
        :first_name,
        :last_name,
        :website,
        genres: []
      )
    end
  end
end