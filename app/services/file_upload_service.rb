require "uploadcare"

class FileUploadService
  def initialize(project, file_params, secret_key)
    @project = project
    @file_params = file_params
    @secret_key = secret_key
    @file_id = Uc::File.generate_id
    @metadata = (@file_params[:metadata]&.to_unsafe_h || {}).merge("file_id" => @file_id)
  end

  def upload
    if @file_params[:source_url]
      upload_url(@file_params[:source_url])
    elsif @file_params[:is_chunked_upload]
      upload_chunked
    else
      upload_file(@file_params[:content])
    end
  end

  def upload_file(file)
    result = Uploadcare::Uploader.upload(file, store: true, metadata: @metadata)
    result = result.first if result.is_a?(Array)
    @project.files.create!(id: @file_id, uuid: result.uuid, source_url: @file_params[:source_url], expires_at: @file_params[:expires_at], uploadcare_show_response: result)
  end

  def upload_url(source_url)
    token = Uploadcare::Uploader.upload_from_url(source_url, async: true, store: true, metadata: @metadata)
    @project.files.create!(id: @file_id, upload_token: token, source_url: @file_params[:source_url], expires_at: @file_params[:expires_at])
  end

  def upload_chunked
    chunk_size = @file_params[:chunk_size] || 5242880
    response = Typhoeus.post(
      "https://upload.uploadcare.com/multipart/start/",
      body: {
        "UPLOADCARE_PUB_KEY" => @project.uuid,
        "UPLOADCARE_STORE" => "1",
        filename: @file_params[:filename],
        size: @file_params[:size],
        part_size: chunk_size,
        content_type: @file_params[:content_type],
        metadata: @metadata
      }
    )
    result = JSON.parse(response.body)
    parts = result["parts"]
    @project.files.create!(
      id: @file_id,
      uuid: result["uuid"],
      is_chunked_upload: true,
      chunked_upload_urls: parts,
      chunked_upload_chunk_size: chunk_size,
      expires_at: @file_params[:expires_at])
  end

  def metadata
  end
end
