require "rails_helper"

RSpec.describe Api::V1::FilesController, type: :request do
  it "should create, update and delete a webhook" do
    post "/api/v1/projects/#{uc_project_id}/webhooks.json", headers: uc_auth_header, params: { webhook: { target_url: "http://localhost", events: ["file.uploaded", "file.info_updated"] } }
    expect(response.status).to eq(200)
    expect(response.data["attributes"]["target_url"]).to eq("http://localhost")
    expect(response.data["attributes"]["events"]).to eq(["file.uploaded", "file.info_updated"])
    expect(response.data["attributes"]["is_active"]).to eq(true)
    expect(response.data["attributes"]["signing_secret"]).to match(/whsec-/)
    id = response.data["id"]

    get "/api/v1/projects/#{uc_project_id}/webhooks/#{id}.json", headers: uc_auth_header
    expect(response.status).to eq(200)
    expect(response.data["attributes"]["target_url"]).to eq("http://localhost")
    expect(response.data["attributes"]["events"]).to eq(["file.uploaded", "file.info_updated"])
    expect(response.data["attributes"]["is_active"]).to eq(true)
    expect(response.data["attributes"]["signing_secret"]).to match(/whsec-/)

    put "/api/v1/projects/#{uc_project_id}/webhooks/#{id}.json", headers: uc_auth_header, params: { webhook: { is_active: false } }
    expect(response.status).to eq(200)
    expect(response.data["attributes"]["is_active"]).to eq(false)

    delete "/api/v1/projects/#{uc_project_id}/webhooks/#{id}.json", headers: uc_auth_header
    expect(response.status).to eq(200)

    get "/api/v1/projects/#{uc_project_id}/webhooks/#{id}.json", headers: uc_auth_header
    expect(response.status).to eq(404)
  end
end
