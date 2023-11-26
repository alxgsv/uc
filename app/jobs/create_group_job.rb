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

    WebhooksService.new(webhook_event, group).trigger
  end
end
