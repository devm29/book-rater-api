class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  private

  def render_errors(record, status: :unprocessable_entity)
    render json: { errors: record.errors.full_messages }, status: status
  end
end
