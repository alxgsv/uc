require "rails_helper"

RSpec.describe Api::V1::GroupsController, type: :request do
  context "group creation and update" do
    it "should create an update group with secret key" do
      perform_enqueued_jobs do
        ids = []
        2.times do
          post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_image_file } }, headers: uc_auth_header
          ids << response.data["id"]
        end
        post "/api/v1/projects/#{uc_project_id}/groups.json", params: { group: { file_ids: ids } }, headers: uc_auth_header
        id = response.data["id"]

        get "/api/v1/projects/#{uc_project_id}/groups/#{id}.json", headers: uc_auth_header
        expect(response.data["attributes"]["status"]).to eq("ready")
        uuid = response.data["attributes"]["uuid"]

        get "/api/v1/projects/#{uc_project_id}/groups/#{id}/files.json", headers: uc_auth_header
        expect(response.data.map { |f| f["id"] }).to eq(ids)

        put "/api/v1/projects/#{uc_project_id}/groups/#{id}.json", params: { group: { file_ids: ids.reverse } }, headers: uc_auth_header
        expect(response.data["id"]).to eq(id)

        get "/api/v1/projects/#{uc_project_id}/groups/#{id}.json", headers: uc_auth_header
        expect(response.data["attributes"]["uuid"]).not_to eq(uuid)

        get "/api/v1/projects/#{uc_project_id}/groups/#{id}/files.json", headers: uc_auth_header
        expect(response.data.map { |f| f["id"] }).to eq(ids.reverse)
      end
    end

    it "should create an update group with access key" do
      perform_enqueued_jobs do
        # list request to store secret_key
        get "/api/v1/projects/#{uc_project_id}/files.json", headers: uc_auth_header

        ids = []
        2.times do
          post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_image_file } }
          ids << response.data["id"]
        end

        post "/api/v1/projects/#{uc_project_id}/groups.json", params: { group: { file_ids: ids } }
        id = response.data["id"]
        token = response.data["authentication"]["access_token"]

        get "/api/v1/projects/#{uc_project_id}/groups/#{id}.json", headers: { "Authorization": "Bearer #{token}" }
        uuid = response.data["attributes"]["uuid"]

        get "/api/v1/projects/#{uc_project_id}/groups/#{id}/files.json", headers: { "Authorization": "Bearer #{token}" }
        expect(response.data.map { |f| f["id"] }).to eq(ids)

        put "/api/v1/projects/#{uc_project_id}/groups/#{id}.json", params: { group: { file_ids: ids.reverse } }, headers:  { "Authorization": "Bearer #{token}" }

        get "/api/v1/projects/#{uc_project_id}/groups/#{id}.json", headers: { "Authorization": "Bearer #{token}" }
        expect(response.data["id"]).to eq(id)
        expect(response.data["attributes"]["uuid"]).not_to eq(uuid)

        get "/api/v1/projects/#{uc_project_id}/groups/#{id}/files.json", headers: { "Authorization": "Bearer #{token}" }
        expect(response.data.map { |f| f["id"] }).to eq(ids.reverse)
      end
    end
  end
end
