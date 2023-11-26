class WebhooksService
  def initialize(event, resource)
    @event = event
    @resource = resource
    @project = @resource.project
  end

  def self.post(url, body, secret)
    body = body.to_json if !body.is_a?(String)
    Typhoeus.post(
      url,
      body: body.to_json,
      headers: {
        "X-Uc-Signature" => OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, body)
      }
    )
  end

  def trigger
    @project.webhooks.where(is_active: true).each do |webhook|
      next if !webhook.events.include?(@event)

      event_body = Api::V1::WebhookEventSerializer.new(webhook, @event, @resource).serialize
      self.class.post(
        webhook.target_url,
        event_body,
        webhook.signing_secret
      )
    end
  end
end
