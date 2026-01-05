class ApplicationController < ActionController::Base
  include Pagy::Method
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Authentication (Phase 1)
  before_action :authenticate_user!

  # Authorization (Phase 2)
  after_action :verify_authorized, except: :index, if: -> { !devise_controller? }
  # Note: verify_policy_scoped disabled due to conflicts with Devise controllers
  # after_action :verify_policy_scoped, only: :index, if: -> { !devise_controller? }

  # Pundit error handling
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Helpers
  helper_method :skip_layout_content_wrapper?, :layout_with_header_width?
  helper_method :t_flash_message

  # Hooks
  before_action :ensure_user_profile_is_complete, unless: :devise_controller?
  before_action :update_app_metadata_daily_usage
  around_action :switch_locale
  around_action :switch_time_zone

  def switch_locale(&action)
    locale = current_user&.locale
    locale = I18n.default_locale if locale.blank?
    response.set_header "Content-Language", locale
    Pagy::I18n.locale = locale
    I18n.with_locale locale, &action
  end

  def switch_time_zone(&block)
    timezone_to_use = if current_user&.timezone.present?
      current_user.timezone
    else
      (I18n.locale == :"pt-BR") ? "Brasilia" : "Central Time (US & Canada)"
    end
    Time.use_zone(timezone_to_use, &block)
  end

  def ensure_user_profile_is_complete
    return unless user_signed_in?
    unless current_user.is_profile_complete?
      redirect_to edit_profile_path
    end
  end

  def update_app_metadata_daily_usage
    AppMetadata.instance.touch_usage!
  end

  # Note: current_user is now provided by Devise (Phase 1)

  def set_layout_with_header_width!
    @layout_with_header_width = true
  end

  def layout_with_header_width?
    @layout_with_header_width
  end

  def skip_layout_content_wrapper!
    @skip_layout_content_wrapper = true
  end

  def skip_layout_content_wrapper?
    @skip_layout_content_wrapper
  end

  def t_flash_message(resource, flash_type: nil)
    flash_type ||= :notice
    t("flash.actions.#{action_name}.#{flash_type}", resource_name: resource.model_name.human)
  end

  def turbo_frame_request?
    request.headers["Turbo-Frame"]
  end

  def render_turbo_alert_message(type, message)
    render turbo_stream: turbo_stream.append(
      "alert-messages",
      partial: "layouts/alert",
      locals: {
        type: type,
        message: message
      }
    )
  end

  private

  def user_not_authorized
    flash[:error] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
