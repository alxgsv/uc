class Api::V1::WebhookEventSerializer
  def initialize(webhook, event, resource)
    @webhook = webhook
    @event = event
    @resource = resource
  end

  def serialize
    {
      data: {
        type: :webhook_events,
        id: "we-" + SecureRandom.alphanumeric(22),
        attributes: {
          event: @event
        },
        relationships: {
          webhook: {
            data: { type: "webhooks", id: @webhook.id }
          },
          resource: {
            data: { type: @resource.class.table_name, id: @resource.id }
          }
        }
      },
      included: [
        serialize_resource,
        serialize_webhook
      ]
    }
  end

  def serialize_webhook
    Api::V1::WebhookSerializer.new(@webhook).serialize
  end

  def serialize_resource
    case @resource
    when Uc::File
      Api::V1::FileSerializer.new(@resource).serialize
    when Uc::Group
      Api::V1::GroupSerializer.new(@resource).serialize
    when Uc::Action
      Api::V1::ActionSerializer.new(@resource).serialize
    end
  end
end
