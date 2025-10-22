class ApplicationController < ActionController::Base
  include ErrorHandling
  
  before_action :basic_auth, unless: :devise_controller?, if: :require_basic_auth?
  before_action :configure_permitted_parameters, if: :devise_controller?

  private
  def require_basic_auth?
    Rails.env.production? && ENV["BASIC_AUTH_USER"].present? && ENV["BASIC_AUTH_PASSWORD"].present?
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV["BASIC_AUTH_USER"] && password == ENV["BASIC_AUTH_PASSWORD"]
    end
  end

  def configure_permitted_parameters
    added_attrs = [:nickname]
    devise_parameter_sanitizer.permit(:sign_up,        keys: added_attrs)
    devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
  end

  # Devise: 新規登録後のリダイレクト先を指定
  def after_sign_up_path_for(resource)
    root_path
  end

  # Devise: ログイン後のリダイレクト先を指定
  def after_sign_in_path_for(resource)
    root_path
  end

  # AIサービス呼び出しの共通エラーハンドリング
  def handle_ai_service_call(service_class, *args)
    begin
      result = service_class.call(*args)
      { success: true, data: result }
    rescue StandardError => e
      Rails.logger.error("[#{service_class.name}] #{e.class}: #{e.message}")
      { success: false, error: e.message }
    end
  end

  # JSON レスポンスの共通化
  def render_json_response(success:, data: nil, error: nil, status: :ok)
    if success
      render json: data, status: status
    else
      # より詳細なエラーメッセージを返す（本番環境での原因特定のため）
      error_message = error.presence || "処理に失敗しました。"
      render json: { error: error_message }, status: :internal_server_error
    end
  end

  # フラッシュメッセージの共通化
  def set_flash_message(type, message)
    flash[type] = message
  end

  # リダイレクト時の共通処理
  def redirect_with_message(path, message, type: :notice)
    redirect_to path, type => message
  end

  # バリデーションエラーの共通処理
  def handle_validation_errors(object, action_name)
    if object.errors.any?
      render action_name, status: :unprocessable_content
    else
      yield if block_given?
    end
  end
end
