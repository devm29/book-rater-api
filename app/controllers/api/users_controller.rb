module API
  class UsersController < ApplicationController
    def create
      user = User.new(allowed_params)

      if user.save
        render json: user, status: :created
      else
        render_errors(user)
      end
    end

    def index
      render json: User.all, status: :ok
    end

    def show
      render json: User.find(params[:id]), status: :ok
    end

    def update
      user = User.find(params[:id])

      if user.update(allowed_params)
        render json: user, status: :ok
      else
        render_errors(user)
      end
    end

    private

    def allowed_params
      params.permit(
        :first_name,
        :last_name
      )
    end
  end
end