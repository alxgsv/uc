class Api::V1::ConversionsController < ApplicationController
  before_action :preload_project_and_file
  before_action :authenticate_user!
  around_action :with_uploadcare_authentication

  def index
    response = Typhoeus.get(
      "https://api.uploadcare.com/convert/document/#{@file.uuid}/",
      headers: {
        "Accept" => "application/vnd.uploadcare-v0.7+json",
        "Authorization" => "Uploadcare.Simple #{@project.uuid}:#{auth_token}"
      }
    )
    response_json = JSON.parse(response.body)["format"].to_h
    methods_available = []
    methods_available += [:video] if @file.is_video?
    methods_available += [:image, :remove_bg] if @file.is_image?
    methods_available += [:document] if !@file.is_video? && !@file.is_image?
    render json: {
      data: {
        type: "conversions",
        attributes: {
          format_current: response_json["name"],
          formats_available: response_json["conversion_formats"].to_a.map { |format| format["name"] },
          methods_available: methods_available }
        }
      }
  end

  def video
    response = Typhoeus.post(
      "https://api.uploadcare.com/convert/video/",
      headers: {
        "Accept" => "application/vnd.uploadcare-v0.7+json",
        "Authorization" => "Uploadcare.Simple #{@project.uuid}:#{auth_token}",
        "Content-Type" => "application/json"
      },
      body: {
        paths: ["#{@file.uuid}/video/-#{recipe}"],
        store: true
      }.to_json
    )
    @project.store_secret_key!(auth_token)
    response_json = JSON.parse(response.body)
    uuid = response_json["result"][0]["uuid"]
    thumbnails_group_uuid = response_json["result"][0]["thumbnails_group_uuid"]
    @result_file = @project.files.create!(uuid: uuid, video_thumbnails_group_uuid: thumbnails_group_uuid)
    render json: {
      data: Api::V1::FileSerializer.new(@result_file, auth_token: auth_token).serialize
    }
  end

  def document
    response = Typhoeus.post(
      "https://api.uploadcare.com/convert/document/",
      headers: {
        "Accept" => "application/vnd.uploadcare-v0.7+json",
        "Authorization" => "Uploadcare.Simple #{@project.uuid}:#{auth_token}",
        "Content-Type" => "application/json"
      },
      body: {
        paths: ["#{@file.uuid}/document/-#{recipe}"],
        store: true
      }.to_json
    )

    @project.store_secret_key!(auth_token)
    response_json = JSON.parse(response.body)
    uuid = response_json["result"][0]["uuid"]
    @result_file = @project.files.create!(uuid: uuid)
    render json: {
      data: Api::V1::FileSerializer.new(@result_file, auth_token: auth_token).serialize
    }
  end

  def image
    file = FileUploadService.new(@project, { source_url: "https://ucarecdn.com/#{@file.uuid}#{recipe}" }, auth_token).upload
    @project.store_secret_key!(auth_token)
    render json: {
      data: Api::V1::FileSerializer.new(file, auth_token: auth_token).serialize
    }
  end

  def remove_bg
    remove_bg_params = recipe.split("/-/").map { |paramval| paramval.sub(/^\//, "").sub(/\/$/, "") }.to_h { |paramvalue| paramvalue.split("/") }
    request_id = Uploadcare::Addons.remove_bg(@file.uuid, **remove_bg_params).request_id
    result_file = @project.files.create!(request_id_remove_bg: request_id)
    render json: {
      data: Api::V1::FileSerializer.new(result_file, auth_token: auth_token).serialize
    }
  end

  private

  def preload_project_and_file
    @project = Uc::Project.find_by!(uuid: params[:project_id])
    @file = @project.files.find_by!(id: params[:file_id])
  end

  def recipe
    params[:recipe]
  end
end
