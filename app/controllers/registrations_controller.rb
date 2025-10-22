# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  # ユーザー登録時の詳細なログとエラーハンドリング
  
  def create
    build_resource(sign_up_params)
    
    # 登録前のログ出力（本番環境でのデバッグ用）
    Rails.logger.info "==== User Registration Attempt ===="
    Rails.logger.info "Email: #{resource.email.inspect}"
    Rails.logger.info "Nickname: #{resource.nickname.inspect}"
    Rails.logger.info "Email present?: #{resource.email.present?}"
    Rails.logger.info "Nickname present?: #{resource.nickname.present?}"
    
    resource.save
    
    yield resource if block_given?
    
    if resource.persisted?
      # 成功
      Rails.logger.info "User registration successful: #{resource.id}"
      
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      # 失敗
      Rails.logger.error "==== User Registration Failed ===="
      Rails.logger.error "Errors: #{resource.errors.full_messages.inspect}"
      Rails.logger.error "Error details: #{resource.errors.details.inspect}"
      
      # 各フィールドのエラーを詳細にログ出力
      resource.errors.each do |error|
        Rails.logger.error "  - Field: #{error.attribute}, Type: #{error.type}, Message: #{error.message}"
      end
      
      # データベースエラーの可能性をチェック
      if resource.errors.empty? && !resource.valid?
        Rails.logger.error "Resource has no validation errors but is invalid - possible DB constraint issue"
      end
      
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  rescue ActiveRecord::RecordNotUnique => e
    # データベースの一意性制約違反
    Rails.logger.error "==== Database Unique Constraint Violation ===="
    Rails.logger.error "Exception: #{e.class}"
    Rails.logger.error "Message: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
    
    # エラーメッセージを適切に設定
    if e.message.include?('email')
      resource.errors.add(:email, :taken, value: resource.email)
    elsif e.message.include?('nickname')
      resource.errors.add(:nickname, :taken, value: resource.nickname)
    else
      resource.errors.add(:base, "データベースの制約違反が発生しました: #{e.message}")
    end
    
    clean_up_passwords resource
    set_minimum_password_length
    respond_with resource
  rescue ActiveRecord::NotNullViolation => e
    # NOT NULL制約違反
    Rails.logger.error "==== Database NOT NULL Constraint Violation ===="
    Rails.logger.error "Exception: #{e.class}"
    Rails.logger.error "Message: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
    
    # どのフィールドがNULLだったかを特定
    if e.message.include?('email')
      resource.errors.add(:email, :blank)
    elsif e.message.include?('nickname')
      resource.errors.add(:nickname, :blank)
    elsif e.message.include?('encrypted_password')
      resource.errors.add(:password, :blank)
    else
      resource.errors.add(:base, "必須フィールドが不足しています: #{e.message}")
    end
    
    clean_up_passwords resource
    set_minimum_password_length
    respond_with resource
  rescue StandardError => e
    # その他のエラー
    Rails.logger.error "==== Unexpected Error During Registration ===="
    Rails.logger.error "Exception: #{e.class}"
    Rails.logger.error "Message: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
    
    resource.errors.add(:base, "予期しないエラーが発生しました。管理者にお問い合わせください。")
    
    clean_up_passwords resource
    set_minimum_password_length
    respond_with resource
  end
  
  protected
  
  def sign_up_params
    params.require(:user).permit(:nickname, :email, :password, :password_confirmation)
  end
  
  def account_update_params
    params.require(:user).permit(:nickname, :email, :password, :password_confirmation, :current_password)
  end
end

