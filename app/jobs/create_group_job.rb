class CreateGroupJob < ApplicationJob
  queue_as :default

  def perform(group_id, file_ids)
    group = Uc::Group.find(group_id)
    group.file_ids = file_ids
    secret_key = group.project.secret_keys.last.secret_key
    uploadcare_group = nil
    UploadcareService.with_credetials(group.project.uuid, secret_key) do
      uploadcare_group = Uploadcare::Group.create(group.files.map(&:uuid))
    end
    webhook_event = group.uuid ? "group.created" : "group.updated"

    group.uuid = uploadcare_group.id
    group.uploadcare_show_response = uploadcare_group
    group.status = :ready
    group.save!

    group.project.webhooks.each do |webhook|
      next if !webhook_event.in?(webhook.events)

      webhook_body = {
        "initiator": {
          "type": "api",
        },
        "hook": {
          "id": webhook.id,
          "project_id": group.project.uuid,
          "created_at": webhook.created_at.iso8601(3),
          "updated_at": webhook.created_at.iso8601(3),
          "event": webhook_event,
          "target": webhook.target,
          "is_active": webhook.is_active,
          "version": "1.0"
        },
        "data": Api::V1::GroupSerializer.new(group, auth_token: secret_key).serialize
      }.to_json

      Typhoeus.post(
        webhook.target_url,
        body: webhook_body,
        headers: {
          "X-Uc-Signature" => OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), webhook.signing_secret, webhook_body)
        }
      )
    end
  end
end
