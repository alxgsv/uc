require "hashie/mash"

class Uc::File < ApplicationRecord
  self.table_name = "files"
  belongs_to :project, class_name: "Uc::Project"

  before_validation :generate_id, :generate_access_token
  before_save :generate_video_thumbnails_group_id

  def self.generate_id
    "f-" + SecureRandom.alphanumeric(22)
  end

  def uploadcare_show_response
    return nil if uploadcare_show_response_json.blank?

    ::Hashie::Mash.quiet.new(JSON.parse(uploadcare_show_response_json))
  end

  def uploadcare_show_response=(response)
    self.uploadcare_show_response_json = response.to_json
  end

  def chunked_upload_urls
    return nil if chunked_upload_urls_json.blank?

    JSON.parse(chunked_upload_urls_json)
  end

  def chunked_upload_urls=(urls)
    self.chunked_upload_urls_json = urls.to_json
  end

  def is_image?
    uploadcare_show_response&.is_image
  end

  def is_video?
    uploadcare_show_response&.content_info&.mime&.type == "video"
  end

  private

  def generate_id
    self.id ||= self.class.generate_id
  end

  def generate_access_token
    self.access_token ||= "fat-" + SecureRandom.alphanumeric(22)
  end

  def generate_video_thumbnails_group_id
    if changes.key?("video_thumbnails_group_uuid")
      files = []
      uploadcare_files = Uploadcare::Group.rest_info(video_thumbnails_group_uuid)["files"]
      uploadcare_files.each do |uploadcare_file|
        files << Uc::File.create_with(uploadcare_show_response: uploadcare_file).find_or_create_by(uuid: uploadcare_file["uuid"])
      end
      group = project.groups.create!(file_ids: files.map(&:id), status: :ready)
      self.video_thumbnails_group_id = group.id
    end
  end
end
