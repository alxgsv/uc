require "uploadcare"
require "hashie/mash"

class UploadcareService
  def self.with_credetials(public_key, secret_key, &block)
    Uploadcare.config.public_key = public_key
    Uploadcare.config.secret_key = secret_key
    yield
    Uploadcare.config.public_key = nil
    Uploadcare.config.secret_key = nil
  end

  def self.file(uuid)
    response = Typhoeus.get(
      "https://api.uploadcare.com/files/#{uuid}/?include=appdata",
      headers: {
        "Accept" => "application/vnd.uploadcare-v0.7+json",
        "Authorization" => "Uploadcare.Simple #{Uploadcare.config.public_key}:#{Uploadcare.config.secret_key}"
      }
    )

    ::Hashie::Mash.quiet.new(JSON.parse(response.body))
  end

  def self.delete(uuid)
    response = Typhoeus.delete(
      "https://api.uploadcare.com/files/#{uuid}/storage/",
      headers: {
        "Accept" => "application/vnd.uploadcare-v0.7+json",
        "Authorization" => "Uploadcare.Simple #{Uploadcare.config.public_key}:#{Uploadcare.config.secret_key}"
      }
    )

    ::Hashie::Mash.quiet.new(JSON.parse(response.body))
  end

  def self.moderate(uuid)
    response = Typhoeus.post("https://api.uploadcare.com/addons/aws_rekognition_detect_moderation_labels/execute/",
      headers: {
        "Accept" => "application/vnd.uploadcare-v0.7+json",
        "Authorization" => "Uploadcare.Simple #{Uploadcare.config.public_key}:#{Uploadcare.config.secret_key}",
        "Content-Type" => "application/json"
      },
      body: {
        target: uuid
      }.to_json)
    JSON.parse(response.body)["request_id"]
  end
end
