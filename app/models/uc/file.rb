require "hashie/mash"

class Uc::File < ApplicationRecord
  self.table_name = "files"
  belongs_to :project, class_name: "Uc::Project"

  before_validation :generate_id, :generate_access_token

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

  def multipart_upload_urls
    return nil if multipart_upload_urls_json.blank?

    JSON.parse(multipart_upload_urls_json)
  end

  def multipart_upload_urls=(urls)
    self.multipart_upload_urls_json = urls.to_json
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
end
