# We need to store keys in the database to mitigate UploadAPI/RestAPI access requirements.
# For example, we want groups to be editable, but REST API for groups requires authentication,
# and we want to preserve the ability to edit groups without authentication.
class Uc::ProjectSecretKey < ApplicationRecord
  self.table_name = "project_secret_keys"
  belongs_to :project, class_name: "Uc::Project"
end
