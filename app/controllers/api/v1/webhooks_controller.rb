class Api::V1::WebhooksController < ApplicationController
  before_action :preload_project_and_webhook
  before_action :require_webhook!, only: [:show, :update, :destroy]
  before_action :authenticate_user!
  around_action :with_uploadcare_authentication

  def index
    pagy, webhooks = pagy(Uc::Webhook.order(created_at: :asc))
    @project.store_secret_key!(auth_token)
    render json: {
      data: webhooks.map { |webhook| Api::V1::WebhookSerializer.new(webhook).serialize },
      **pagy_json(pagy)
    }
  end

  def show
    render json: {
      data: Api::V1::WebhookSerializer.new(@webhook).serialize
    }
  end

  def create
    WebhooksService.new(@project, auth_token).setup_uploadcare_webhooks
    @project.store_secret_key!(auth_token)
    webhook = @project.webhooks.create!(webhook_params)
    render json: {
      data: Api::V1::WebhookSerializer.new(webhook).serialize
    }
  end

  def update
    @webhook.update!(webhook_params)
    render json: {
      data: Api::V1::WebhookSerializer.new(@webhook).serialize
    }
  end

  def destroy
    @webhook.destroy

    render json: {
      data: Api::V1::WebhookSerializer.new(@webhook).serialize
    }
  end

  def incoming
    event = params[:hook][:event]
    @project.webhooks.each do |webhook|
      next if !event.in?(webhook.events)

      transformed_webhook = WebhooksService.new(@project, auth_token).transform_webhook(JSON.parse(request.raw_post)).to_json
      Typhoeus.post(
        webhook.target_url,
        body: transformed_webhook,
        headers: {
          "X-Uc-Signature" => OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), webhook.signing_secret, transformed_webhook)
        }
      )
    end
  end

  private

  def preload_project_and_webhook
    @project = Uc::Project.find_or_create_by(uuid: params[:project_id])
    @webhook = @project.webhooks.find_by(id: params[:id])
  end

  def require_webhook!
    render json: { errors: ["Webhook not found"] }, status: :not_found unless @webhook
  end

  def webhook_params
    params.require(:webhook).permit(:target_url, :is_active, events: [])
  end
end
