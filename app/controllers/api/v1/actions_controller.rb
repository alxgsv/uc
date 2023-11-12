class Api::V1::ActionsController < ApplicationController
  before_action :preload_project_and_file
  before_action :authenticate_user!
  around_action :with_uploadcare_authentication

  def recognize
    if request.post? && @file.request_id_aws_rekognition_detect_labels.blank? && @file.uploadcare_show_response&.appdata&.aws_rekognition_detect_labels.blank?
      request_id = Uploadcare::Addons.ws_rekognition_detect_labels(@file.uuid)
      @file.update!(request_id_aws_rekognition_detect_labels: request_id)
    end
    uploadcare_file = UploadcareService.file(@file.uuid)
    @file.update!(uploadcare_show_response: uploadcare_file)
    result = uploadcare_file&.appdata&.aws_rekognition_detect_labels
    render json: {
      data: {
        type: "recognize_result",
        attributes: {
          status: result ? :ready : :pending,
          result: result
        }
      }
    }
  end

  def moderate
    if request.post? && @file.request_id_aws_rekognition_moderate.blank? && @file.uploadcare_show_response&.appdata&.aws_rekognition_detect_moderation_labels.blank?
      request_id = UploadcareService.moderate(@file.uuid)
      @file.update!(request_id_aws_rekognition_moderate: request_id)
    end
    uploadcare_file = UploadcareService.file(@file.uuid)
    @file.update!(uploadcare_show_response: uploadcare_file)
    result = uploadcare_file&.appdata&.aws_rekognition_detect_moderation_labels
    render json: {
      data: {
        type: "moderate_result",
        attributes: {
          status: result ? :ready : :pending,
          result: result
        }
      }
    }
  end

  def virus_scan
    if request.post? && @file.request_id_clamav.blank? && @file.uploadcare_show_response&.appdata&.uc_clamav_virus_scan.blank?
      request_id = Uploadcare::Addons.uc_clamav_virus_scan(@file.uuid)
      @file.update!(request_id_clamav: request_id)
    end
    uploadcare_file = UploadcareService.file(@file.uuid)
    @file.update!(uploadcare_show_response: uploadcare_file)
    result = uploadcare_file&.appdata&.uc_clamav_virus_scan
    render json: {
      data: {
        type: "virus_scan_result",
        attributes: {
          status: result ? :ready : :pending,
          result: result
        }
      }
    }
  end

  private

  def preload_project_and_file
    @project = Uc::Project.find_by!(uuid: params[:project_id])
    @file = @project.files.find_by!(id: params[:file_id])
  end
end
