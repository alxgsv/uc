require "rails_helper"

RSpec.describe Api::V1::ConversionsController, type: :request do
    it "should convert video" do
      post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_video_file } }
      expect(response.data["attributes"]["status"]).to eq("ready")
      id = response.data["id"]

      get "/api/v1/projects/#{uc_project_id}/files/#{id}/conversions.json", headers: uc_auth_header
      expect(response.data["attributes"]["format_current"]).to eq("mp4")
      expect(response.data["attributes"]["formats_available"]).to include("ogg")

      post "/api/v1/projects/#{uc_project_id}/files/#{id}/conversions/video.json", params: { recipe: "/format/ogg/-/quality/best/" }, headers: uc_auth_header
      expect(response.data["attributes"]["content"]["video"]["thumbnails_group_uuid"]).to be_present
    end

    it "should convert document" do
      post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_pdf_file } }
      expect(response.data["attributes"]["status"]).to eq("ready")
      id = response.data["id"]

      get "/api/v1/projects/#{uc_project_id}/files/#{id}/conversions.json", headers: uc_auth_header
      expect(response.data["attributes"]["format_current"]).to eq("pdf")
      expect(response.data["attributes"]["formats_available"]).to include("docx")

      post "/api/v1/projects/#{uc_project_id}/files/#{id}/conversions/document.json", params: { recipe: "/format/png/" }, headers: uc_auth_header
      expect(response.data["attributes"]["uuid"]).not_to be_blank
    end

    it "should convert image" do
      post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_image_file } }
      expect(response.data["attributes"]["status"]).to eq("ready")
      id = response.data["id"]

      get "/api/v1/projects/#{uc_project_id}/files/#{id}/conversions.json", headers: uc_auth_header

      expect(response.data["attributes"]["format_current"]).to eq("png")
      expect(response.data["attributes"]["formats_available"]).to include("webp")

      post "/api/v1/projects/#{uc_project_id}/files/#{id}/conversions/image.json", params: { recipe: "/format/webp/" }, headers: uc_auth_header
      expect(response.data["id"]).not_to be_blank
    end

    it "should try to remove background from the image without background and get an error" do
      post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_image_file } }
      expect(response.data["attributes"]["status"]).to eq("ready")
      id = response.data["id"]

      get "/api/v1/projects/#{uc_project_id}/files/#{id}/conversions.json", headers: uc_auth_header
      expect(response.data["attributes"]["format_current"]).to eq("png")
      expect(response.data["attributes"]["formats_available"]).to include("webp")
      expect(response.data["attributes"]["methods_available"]).to include("remove_bg")

      post "/api/v1/projects/#{uc_project_id}/files/#{id}/conversions/remove_bg.json", params: { recipe: "/position/original/" }, headers: uc_auth_header
      expect(response.data["id"]).not_to be_blank
      id = response.data["id"]

      sleep(5)

      get "/api/v1/projects/#{uc_project_id}/files/#{id}.json", headers: uc_auth_header
      expect(response.data["attributes"]["status"]).to eq("processing_error")
      expect(response.data["attributes"]["uuid"]).to be_blank
    end

    it "should remove background from an image" do
      post "/api/v1/projects/#{uc_project_id}/files.json", params: { file: { content: test_image_file("book.jpg") } }
      expect(response.data["attributes"]["status"]).to eq("ready")
      id = response.data["id"]

      get "/api/v1/projects/#{uc_project_id}/files/#{id}/conversions.json", headers: uc_auth_header
      expect(response.data["attributes"]["format_current"]).to eq("jpg")
      expect(response.data["attributes"]["formats_available"]).to include("webp")
      expect(response.data["attributes"]["methods_available"]).to include("remove_bg")

      post "/api/v1/projects/#{uc_project_id}/files/#{id}/conversions/remove_bg.json", params: { recipe: "/position/original/" }, headers: uc_auth_header
      expect(response.data["id"]).not_to be_blank
      id = response.data["id"]

      sleep(10)

      get "/api/v1/projects/#{uc_project_id}/files/#{id}.json", headers: uc_auth_header
      expect(response.data["attributes"]["status"]).to eq("ready")
      expect(response.data["attributes"]["uuid"]).not_to be_blank
    end
  end
