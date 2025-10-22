# Common Error Handling Module
module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_standard_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  end

  private

  def handle_standard_error(exception)
    Rails.logger.error("[#{self.class.name}] #{exception.class}: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n")) if Rails.env.development?

    error_message = if Rails.env.production?
      "サーバーエラーが発生しました。しばらく時間をおいてから再度お試しください。"
    else
      "#{exception.class}: #{exception.message}"
    end

    if request.format.json?
      render json: { error: error_message }, status: :internal_server_error
    else
      redirect_with_message(root_path, error_message, type: :alert)
    end
  end

  def handle_record_not_found(exception)
    Rails.logger.warn("[#{self.class.name}] Record not found: #{exception.message}")

    if request.format.json?
      render json: { error: "指定されたリソースが見つかりません。" }, status: :not_found
    else
      redirect_with_message(root_path, "指定されたページが見つかりません。", type: :alert)
    end
  end

  def handle_parameter_missing(exception)
    Rails.logger.warn("[#{self.class.name}] Parameter missing: #{exception.message}")

    if request.format.json?
      render json: { error: "必要なパラメータが不足しています。" }, status: :bad_request
    else
      redirect_with_message(root_path, "リクエストに問題があります。", type: :alert)
    end
  end
end
