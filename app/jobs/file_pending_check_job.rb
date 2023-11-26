class FilePendingCheckJob < ApplicationJob
  queue_as :default

  def perform(file_id)
    file = Uc::File.find(file_id)
    secret_key = file.project.secret_keys.last.secret_key

    10.times do |i|
      if file.uuid.blank? && file.upload_token
        result = UploadcareService.with_credetials(group.project.uuid, secret_key) do
          Uploadcare::Uploader.get_upload_from_url_status(file.upload_token).deconstruct.first
        end
        file.update(uploadcare_show_response: result, uuid: result[:uuid])
      end

      if file.status != "pending"
        WebhooksService.new("file.updated", file).trigger
        return
      end

      sleep i
    end
  end
end
