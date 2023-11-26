class Api::V1::ActionsController < ApplicationController
  before_action :preload_project_and_file
  before_action :authenticate_user!
  around_action :with_uploadcare_authentication

  def recognize
    if request.post? && @file.request_id_aws_rekognition_detect_labels.blank? && @file.uploadcare_show_response&.appdata&.aws_rekognition_detect_labels.blank?
      request_id = Uploadcare::Addons.ws_rekognition_detect_labels(@file.uuid)
      @file.update!(request_id_aws_rekognition_detect_labels: request_id)
      action = Uc::Action.find_or_create_by(project: @project, file: @file, action_type: :recognize)
      WebhooksService.new("action.created", action).trigger
      ActionPendingCheckJob.perform_later(action.id)
    end
    action ||= Uc::Action.find_by(project: @project, file: @file, action_type: :recognize)
    uploadcare_file = UploadcareService.file(@file.uuid)
    @file.update!(uploadcare_show_response: uploadcare_file)
    render json: {
      data: Api::V1::ActionSerializer.new(action).serialize
    }
  end

  def moderate
    if request.post? && @file.request_id_aws_rekognition_moderate.blank? && @file.uploadcare_show_response&.appdata&.aws_rekognition_detect_moderation_labels.blank?
      request_id = UploadcareService.moderate(@file.uuid)
      @file.update!(request_id_aws_rekognition_moderate: request_id)
      action = Uc::Action.find_or_create_by(project: @project, file: @file, action_type: :moderate)
      WebhooksService.new("action.created", action).trigger
      ActionPendingCheckJob.perform_later(action.id)
    end
    action ||= Uc::Action.find_by(project: @project, file: @file, action_type: :moderate)
    uploadcare_file = UploadcareService.file(@file.uuid)
    @file.update!(uploadcare_show_response: uploadcare_file)
    render json: {
      data: Api::V1::ActionSerializer.new(action).serialize
    }
  end

  def virus_scan
    if request.post? && @file.request_id_clamav.blank? && @file.uploadcare_show_response&.appdata&.uc_clamav_virus_scan.blank?
      request_id = Uploadcare::Addons.uc_clamav_virus_scan(@file.uuid)
      @file.update!(request_id_clamav: request_id)
      action = Uc::Action.find_or_create_by(project: @project, file: @file, action_type: :virus_scan)
      WebhooksService.new("action.created", action).trigger
      ActionPendingCheckJob.perform_later(action.id)
    end
    action ||= Uc::Action.find_or_create_by(project: @project, file: @file, action_type: :virus_scan)
    uploadcare_file = UploadcareService.file(@file.uuid)
    @file.update!(uploadcare_show_response: uploadcare_file)
    render json: {
      data: Api::V1::ActionSerializer.new(action).serialize
    }
  end

  private

  def preload_project_and_file
    @project = Uc::Project.find_by!(uuid: params[:project_id])
    @file = @project.files.find_by!(id: params[:file_id])
  end
end
