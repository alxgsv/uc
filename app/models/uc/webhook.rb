class Uc::Webhook < ActiveRecord::Base
  self.table_name = "webhooks"

  belongs_to :project, class_name: "Uc::Project"

  serialize :events, coder: JSON

  before_validation :generate_id, :generate_signing_secret

  private

  def generate_id
    self.id ||= "wh-" + SecureRandom.alphanumeric(22)
  end

  def generate_signing_secret
    self.signing_secret ||= "whsec-" + SecureRandom.alphanumeric(22)
  end
end
