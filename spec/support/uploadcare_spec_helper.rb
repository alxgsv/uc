def uc_project_id
  ENV["UC_PROJECT_ID"]
end

def uc_secret_key
  ENV["UC_SECRET_KEY"]
end

def uc_auth_header
  { "Authorization" => "Bearer #{uc_secret_key}" }
end

def test_image_file(filename = nil)
  Rack::Test::UploadedFile.new(Rails.root.join("spec", "fixtures", (filename || "blank.png")), "image/png")
end

def test_video_file
  Rack::Test::UploadedFile.new(Rails.root.join("spec", "fixtures", "sample.mp4"), "video/mp4")
end

def test_pdf_file
  Rack::Test::UploadedFile.new(Rails.root.join("spec", "fixtures", "sample.pdf"), "application/pdf")
end

RSpec::Matchers.define :be_iso8601_date do |expected, precision|
  match do |actual|
    # Parse the actual and expected values as dates
    actual_datetime = DateTime.parse(actual)
    expected_datetime = DateTime.parse(expected)

    (actual_datetime - expected_datetime).to_f <= precision.to_f
  end
end
