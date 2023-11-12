class WebhooksService
  EVENTS = ["file.uploaded", "file.infected", "file.stored", "file.deleted", "file.info_updated"].freeze

  def initialize(project, secret_key=nil)
    @project = project
    @secret_key = secret_key || @project.secret_keys.last&.secret_key
  end

  def transform_webhook(webhook)
    uploadcare_file = webhook[:data]
    uuid = uploadcare_file[:uuid]
    file = @project.files.find_by(id: uploadcare_file[:metadata][:file_id])
    if file.uuid.blank?
      file.update!(uploadcare_show_response: uploadcare_file, uuid: uuid)
    end
    webhook[:data] = Api::V1::FileSerializer.new(file).serialize
    webhook
  end

  def setup_uploadcare_webhooks
    existing_webhooks = Uploadcare::Webhook.list
    webhook_params.each do |webhook_params|
      if existing_webhooks.find { |webhook| webhook.target_url == webhook_params[:target_url] }.blank?
        Uploadcare::Webhook.create(webhook_params)
      end
    end
  end

  def webhook_params
    EVENTS.map do |event|
      {
        target_url: url_for_event(event),
        event: event,
        is_active: true,
        signing_secret: signing_secret(event)
      }
    end
  end

  def signing_secret(event)
    Digest::SHA2.hexdigest(Rails.application.secret_key_base + @project.uuid + event)[0..31]
  end

  def url_for_event(event)
    host = Rails.application.routes.default_url_options[:host]
    "https://#{host}/api/v1/projects/#{@project.uuid}/webhooks/incoming?event=#{event}"
  end
end
