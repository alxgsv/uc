class Api::V1::WebhookSerializer
  def initialize(webhook, auth_token: nil)
    @webhook = webhook
  end

  def serialize
    {
      type: :webhooks,
      id: @webhook.id,
      attributes: {
        events: @webhook.events,
        target_url: @webhook.target_url,
        is_active: @webhook.is_active,
        version: @webhook.version,
        signing_secret: @webhook.signing_secret
      },
      relationships: {
        project: {
          data: { type: "projects", id: @webhook.project.uuid }
        }
      }
    }
  end
end
