class Api::V1::FilesController < ApplicationController
  before_action :preload_project_and_file
  before_action :authenticate_user!, only: [:index, :show, :update, :destroy]
  around_action :with_uploadcare_authentication, only: [:index, :show, :create, :update, :destroy]

  def index
    pagy, files = pagy(@project.files.order(created_at: :asc))
    @project.store_secret_key!(auth_token)
    render json: {
      data: files.map { |group| Api::V1::FileSerializer.new(group, auth_token: project_secret_key).serialize },
      **pagy_json(pagy)
    }
  end

  def show
    file = @project.files.find_by(id: params[:id])
    # Uploadcare File is not yet ready, check it's status and update it's uuid if it's ready
    if file.uuid.blank? && file.upload_token
      result = Uploadcare::Uploader.get_upload_from_url_status(file.upload_token).deconstruct.first
      if result[:uuid]
        file.update(uploadcare_show_response: result, uuid: result[:uuid])
      end
    elsif file.uuid.blank? && file.request_id_remove_bg.present?
      status_response = Uploadcare::Addons.remove_bg_status(file.request_id_remove_bg)
      if status_response["status"] == "done"
        uuid = status_response["result"]["file_id"]
        file.update(uuid: uuid, uploadcare_show_response: UploadcareService.file(uuid))
      elsif status_response["status"] == "error"
        file.update(status: :processing_error)
      end
    end

    @project.store_secret_key!(auth_token)

    render json: {
      data: Api::V1::FileSerializer.new(file, auth_token: project_secret_key).serialize
    }
  end

  def update
    file = @project.files.find_by(id: params[:id])
    FileMetadataService.new(file).update(params[:file][:metadata])
    if file.is_multipart_upload && !file.is_multipart_upload_complete && file_params[:is_multipart_upload_complete] == "true"
      file.is_multipart_upload_complete = true
      file.multipart_upload_urls = []
      Typhoeus.post(
        "https://upload.uploadcare.com/multipart/complete/",
        body: {
          "UPLOADCARE_PUB_KEY" => @project.uuid,
          uuid: file.uuid
        }
      )
    end
    file.expires_at = file_params[:expires_at] if file_params[:expires_at]

    file.uploadcare_show_response = UploadcareService.file(file.uuid)
    file.save!
    @project.store_secret_key!(auth_token)
    render json: {
      data: Api::V1::FileSerializer.new(file, auth_token: project_secret_key).serialize
    }
  end

  def create
    file = FileUploadService.new(@project, file_params, auth_token).upload
    @project.store_secret_key!(auth_token)
    render json: {
      data: Api::V1::FileSerializer.new(file, auth_token: project_secret_key).serialize
    }
  end

  def destroy
    file = @project.files.find_by(id: params[:id])
    UploadcareService.delete(file.uuid)
    file.update!(uploadcare_show_response: UploadcareService.file(file.uuid))
    render json: {
      data: Api::V1::FileSerializer.new(file, auth_token: project_secret_key).serialize
    }
  end

  private

  def preload_project_and_file
    @project = Uc::Project.find_or_create_by(uuid: params[:project_id])
    @file = @project.files.find_by(id: params[:id]) if params[:id]
  end

  def resource_access_token
    @file&.access_token
  end

  def file_params
    params.require(:file).permit(:is_multipart_upload, :is_multipart_upload_complete, :filename, :size, :content_type, :part_size, :source_url, :content, :expires_at, metadata: {})
  end
end