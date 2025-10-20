class ApplicationController < ActionController::Base
  include ErrorHandling
  
  before_action :basic_auth, unless: -> { Rails.env.test? }
  before_action :configure_permitted_parameters, if: :devise_controller?

  private
  def basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV["BASIC_AUTH_USER"] && password == ENV["BASIC_AUTH_PASSWORD"]
    end
  end

  def configure_permitted_parameters
    added_attrs = [:nickname, :email, :password, :password_confirmation]
    devise_parameter_sanitizer.permit(:sign_up,        keys: added_attrs)
    devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
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
      error_message = error&.include?('Translation') ? error : "フィードバック生成に失敗しました。"
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
