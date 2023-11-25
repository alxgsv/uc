class ApplicationController < ActionController::Base
  include Pagy::Backend

  skip_forgery_protection

  def auth_token
    request.headers["Authorization"].to_s.split(" ").last
  end

  def pagy_json(pagy)
    {
      pagination: {
        count: pagy.count,
        page: pagy.page,
        items: pagy.items,
        pages: pagy.pages
      }
    }
  end

  def authenticated_user?
    return false if auth_token.blank?
    return true if self.respond_to?(:resource_access_token, true) && resource_access_token && resource_access_token == auth_token

    begin
      UploadcareService.with_credetials(@project.uuid, auth_token) do
        Uploadcare::FileList.file_list(limit: 1)
      end
    rescue
      return false
    end

    true
  end

  def authenticate_user!
    return if authenticated_user?

    render json: { errors: ["Unauthorized"] }, status: :unauthorized and return
  end

  def with_uploadcare_authentication(&block)
    UploadcareService.with_credetials(@project.uuid, project_secret_key, &block)
  end

  def project_secret_key
    if auth_token && self.respond_to?(:resource_access_token, true) && auth_token == resource_access_token
      @project.secret_keys.last.secret_key
    else
      auth_token
    end
  end
end
