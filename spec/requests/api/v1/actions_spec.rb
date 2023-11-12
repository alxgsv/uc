require "rails_helper"

RSpec.describe Api::V1::ActionsController, type: :request do
  it "should recognize image" do
    # list request to store secret_key
    post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_image_file } }
    expect(response.data["attributes"]["status"]).to eq("ready")
    id = response.data["id"]

    post "/api/v1/projects/#{uc_project_id}/files/#{id}/actions/recognize.json", headers: uc_auth_header
    expect(response.data["attributes"]["status"]).to eq("ready")
    expect(response.data["attributes"]["result"]).not_to be_blank
  end
  it "should moderate image" do
    # list request to store secret_key
    post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_image_file } }
    expect(response.data["attributes"]["status"]).to eq("ready")
    id = response.data["id"]

    post "/api/v1/projects/#{uc_project_id}/files/#{id}/actions/moderate.json", headers: uc_auth_header
    expect(response.data["attributes"]["status"]).to eq("pending")
    expect(response.data["attributes"]["result"]).to be_blank

    sleep(5)
    get "/api/v1/projects/#{uc_project_id}/files/#{id}/actions/moderate.json", headers: uc_auth_header
    expect(response.data["attributes"]["result"]).not_to be_blank
  end

  it "should virus scan file" do
    # list request to store secret_key
    post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_image_file } }
    expect(response.data["attributes"]["status"]).to eq("ready")
    id = response.data["id"]

    post "/api/v1/projects/#{uc_project_id}/files/#{id}/actions/virus_scan.json", headers: uc_auth_header
    expect(response.data["attributes"]["status"]).to eq("ready")
    expect(response.data["attributes"]["result"]).not_to be_blank
  end
end
