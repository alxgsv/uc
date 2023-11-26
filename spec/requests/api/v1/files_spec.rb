require "rails_helper"

RSpec.describe Api::V1::FilesController, type: :request do
  around(:each) do |example|
    perform_enqueued_jobs do
      post "/api/v1/projects/#{uc_project_id}/webhooks.json", headers: uc_auth_header, params: { webhook: { target_url: "http://localhost:8080/webhook", events: ["file.created", "file.updated", "file.deleted", "group.created", "group.updated", "group.deleted", "action.created", "action.updated"] } }
      example.run
    end
  end

  context "file listing" do
    it "should list and paginate files" do
      post "/api/v1/projects/#{uc_project_id}/files.json", headers: uc_auth_header, params: { file: { content: test_image_file } }
      get "/api/v1/projects/#{uc_project_id}/files.json", headers: uc_auth_header, params: { items: 1 }
      expect(response.data[0]["attributes"]["status"]).to eq("ready")
      expect(response.data.size).to eq(1)
      expect(response.pagination).not_to eq({ items: 1, count: 1, page: 1, pages: 1 })
    end
  end

  context "file creation" do
    it "should upload from url" do
      # list request to store secret_key
      get "/api/v1/projects/#{uc_project_id}/files.json", headers: uc_auth_header

      post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { source_url: "https://live.staticflickr.com/4765/39926271622_b290091d4f_6k.jpg" } }
      expect(response.data["attributes"]["status"]).to eq("pending")
      expect(response.data["attributes"]["uuid"]).to eq(nil)
      id = response.data["id"]
      token = response.data["authentication"]["access_token"]
      sleep(5)
      get "/api/v1/projects/#{uc_project_id}/files/#{id}.json", headers: { "Authorization": "Bearer #{token}" }
      expect(response.data["attributes"]["status"]).to eq("ready")
      expect(response.data["attributes"]["uuid"]).not_to eq(nil)
      expect(response.data["attributes"]["original_name"]).to eq("39926271622_b290091d4f_6k.jpg")
    end

    it "should upload from request" do
      # list request to store secret_key
      get "/api/v1/projects/#{uc_project_id}/files.json", headers: uc_auth_header
      post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_image_file } }
      expect(response.data["attributes"]["status"]).to eq("ready")
      expect(response.data["attributes"]["uuid"]).not_to eq(nil)
    end

    it "should upload directly to s3" do
      post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { is_chunked_upload: true, size: 18462554, chunk_size: 10485760, filename: "20mb.jpg", content_type: "image/jpeg" }, headers: uc_auth_header }
      id = response.data["id"]
      urls = response.data["chunked_upload_urls"]
      expect(response.data["attributes"]["status"]).to eq("pending")
      expect(response.data["attributes"]["uuid"]).not_to eq(nil)
      files = ["20mb_1.jpg", "20mb_2.jpg"]
      urls.each_with_index do |url, index|
        Typhoeus.put(url, body: File.read(Rails.root.join("spec", "fixtures", files[index])), headers: { "Content-Type": "application/octet-stream" })
      end
      put "/api/v1/projects/#{uc_project_id}/files/#{id}.json", params: { file: { is_chunked_upload_complete: true } }, headers: uc_auth_header
      expect(response.data["attributes"]["status"]).to eq("ready")
      expect(response.data["attributes"]["uuid"]).not_to eq(nil)
    end
  end

  context "file update" do
    it "should set some keys in metadata" do
      post "/api/v1/projects/#{uc_project_id}/files.json", headers: uc_auth_header, params: { file: { content: test_image_file, metadata: { m1: "1", current_timestamp: "2023-11-05T07:09:30+00:00" } } }
      put "/api/v1/projects/#{uc_project_id}/files/#{response.data["id"]}.json", headers: uc_auth_header, params: { file: { metadata: [ { key: :m1, value: "2" } ] } }
      expect(response.data["attributes"]["metadata"]).to eq({ m1: "2", current_timestamp: "2023-11-05T07:09:30+00:00" }.stringify_keys)
    end

    it "should rewrite metadata" do
      post "/api/v1/projects/#{uc_project_id}/files.json", headers: uc_auth_header, params: { file: { content: test_image_file, metadata: { m1: "1", m2: "2" } } }
      put "/api/v1/projects/#{uc_project_id}/files/#{response.data["id"]}.json", headers: uc_auth_header, params: { file: { metadata: { m1: "2", m3: "3" } } }
      expect(response.data["attributes"]["metadata"]).to eq({ m1: "2", m3: "3" }.stringify_keys)
    end
  end

  context "file deletion" do
    it "should delete a file" do
      # list request to store secret_key
      get "/api/v1/projects/#{uc_project_id}/files.json", headers: uc_auth_header

      post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_image_file } }
      id = response.data["id"]
      token = response.data["authentication"]["access_token"]
      delete "/api/v1/projects/#{uc_project_id}/files/#{id}.json", headers: { "Authorization": "Bearer #{token}" }
      expect(response.status).to eq(200)
      expect(response.data["attributes"]["status"]).to eq("removed")
      expect(response.data["attributes"]["removed_at"]).to be_iso8601_date(Time.now.utc.iso8601, 10.seconds)
    end
  end
end
