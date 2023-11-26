class ActionPendingCheckJob < ApplicationJob
  queue_as :default

  def perform(action_id)
    action = Uc::Action.find(action_id)
    file = action.file
    secret_key = action.project.secret_keys.last.secret_key

    10.times do |i|
      uploadcare_file = UploadcareService.with_credetials(action.project.uuid, secret_key) do
        UploadcareService.file(file.uuid)
      end
      file.update!(uploadcare_show_response: uploadcare_file)
      if action.reload.status == "ready"
        WebhooksService.new("action.updated", action).trigger
        return
      end

      sleep i
    end
  end
end
