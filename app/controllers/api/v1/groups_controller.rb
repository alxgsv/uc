require "pagy/extras/array"

class Api::V1::GroupsController < ApplicationController
  before_action :preload_project_and_group
  before_action :authenticate_user!, only: [:index, :show, :update, :destroy, :files]
  around_action :with_uploadcare_authentication, only: [:index, :show, :create, :update, :destroy, :files]

  def index
    pagy, groups = pagy(@project.groups.order(created_at: :asc))
    render json: {
      data: groups.map { |group| Api::V1::GroupSerializer.new(group, auth_token: auth_token).serialize },
      **pagy_json(pagy)
    }
  end

  def show
    render json: {
      data: Api::V1::GroupSerializer.new(@group, auth_token: project_secret_key).serialize
    }
    @project.store_secret_key!(auth_token)
  end

  def create
    @group = @project.groups.create!(file_ids: file_ids, status: :pending)
    CreateGroupJob.perform_later(@group.id, file_ids)
    WebhooksService.new("group.created", @group).trigger
    @project.store_secret_key!(auth_token)
    render json: {
      data: Api::V1::GroupSerializer.new(@group, auth_token: project_secret_key).serialize
    }
  end

  def update
    @group.update!(file_ids: file_ids, status: "pending")
    CreateGroupJob.perform_later(@group.id, file_ids)
    WebhooksService.new("group.created", @group).trigger
    @project.store_secret_key!(auth_token)
    render json: {
      data: Api::V1::GroupSerializer.new(@group, auth_token: project_secret_key).serialize
    }
  end

  def destroy
    Uploadcare::Group.delete(@group.uuid)
    WebhooksService.new("group.deleted", @group).trigger
    @project.store_secret_key!(auth_token)
  end

  def files
    pagy, file_ids = pagy_array(@group.file_ids)
    files = @project.files.where(id: file_ids).to_a.sort_by { |f| file_ids.index(f.id) }
    render json: {
      data: files.map { |file| Api::V1::FileSerializer.new(file, auth_token: project_secret_key).serialize },
      **pagy_json(pagy)
    }
  end

  private

  def preload_project_and_group
    @project = Uc::Project.find_or_create_by(uuid: params[:project_id])
    @group = @project.groups.find_by(id: params[:id]) if params[:id]
  end

  def resource_access_token
    @group&.access_token
  end

  def file_ids
    params[:group][:file_ids].map(&:strip).uniq
  end

  def project_secret_key
    if @group && auth_token == @group.access_token
      @group.project.secret_keys.last.secret_key
    else
      auth_token
    end
  end
end
