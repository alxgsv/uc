class Uc::Group < ApplicationRecord
  self.table_name = "groups"

  belongs_to :project, class_name: "Uc::Project"

  serialize :file_ids, coder: JSON

  before_validation :generate_id, :generate_access_token

  def files
    Uc::File.where(id: file_ids).to_a.sort_by { |f| file_ids.index(f.id) }
  end

  def uploadcare_show_response
    return nil if uploadcare_show_response_json.blank?

    Hashie::Mash.quiet.new(JSON.parse(uploadcare_show_response_json))
  end

  def uploadcare_show_response=(response)
    self.uploadcare_show_response_json = response.to_json
  end

  private

  def generate_id
    self.id ||= "g-" + SecureRandom.alphanumeric(22)
  end

  def generate_access_token
    self.access_token ||= "gat-" + SecureRandom.alphanumeric(22)
  end
end
