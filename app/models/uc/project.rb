class Uc::Project < ApplicationRecord
  self.table_name = "projects"
  has_many :files, dependent: :destroy, class_name: "Uc::File"
  has_many :groups, dependent: :destroy, class_name: "Uc::Group"
  has_many :secret_keys, dependent: :destroy, class_name: "Uc::ProjectSecretKey"
  has_many :webhooks, dependent: :destroy, class_name: "Uc::Webhook"

  def store_secret_key!(secret_key)
    return if secret_key.blank?
    return if secret_key.include?("-")

    secret_keys.find_or_create_by(secret_key: secret_key)
  end
end
