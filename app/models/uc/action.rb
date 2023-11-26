class Uc::Action < ApplicationRecord
  self.table_name = "actions"
  belongs_to :project, class_name: "Uc::Project"
  belongs_to :file, class_name: "Uc::File"

  before_validation :generate_id

  def self.generate_id
    "a-" + SecureRandom.alphanumeric(22)
  end

  def status
    result.present? ? "ready" : "pending"
  end

  def result
    case action_type
    when "recognize"
      file.uploadcare_show_response&.appdata&.aws_rekognition_detect_labels
    when "moderate"
      file.uploadcare_show_response&.appdata&.aws_rekognition_detect_moderation_labels
    when "virus_scan"
      file.uploadcare_show_response&.appdata&.uc_clamav_virus_scan
    end
  end

  private

  def generate_id
    self.id ||= self.class.generate_id
  end
end
