class Api::V1::FileSerializer
  def initialize(file, auth_token: nil)
    @file = file
    @uc_file = begin
      @file.uploadcare_show_response || (@file.uuid && UploadcareService.file(@file.uuid))
    rescue TypeError => exception
      Hashie::Mash.new
    end
  end

  def status
    if @file.status
      @file.status
    elsif @uc_file.blank?
      :pending
    elsif @uc_file.datetime_removed
      :removed
    elsif @uc_file.is_ready
      :ready
    else
      :pending
    end
  end

  def serialize
    {
      type: :files,
      id: @file.id,
      attributes: {
        uuid: @file.uuid,
        is_image: @uc_file&.is_image,
        status: status,
        mime: @uc_file&.content_info&.mime,
        original_url: @uc_file&.original_file_url,
        original_name: @uc_file&.original_filename,
        size: @uc_file&.size,
        multipart_upload: {
          is_multipart_upload: @file.is_multipart_upload,
          multipart_upload_part_size: @file.multipart_upload_part_size,
          is_multipart_upload_complete: @file.is_multipart_upload_complete
        },
        timestamps: {
          created_at: @file.created_at,
          uploaded_at: @uc_file&.datetime_uploaded,
          removed_at: @uc_file&.datetime_removed,
          expires_at: @file.expires_at
        },
        metadata: FileMetadataService.new(self).show(@uc_file&.metadata),
        content: {
          image: @uc_file&.content_info&.image,
          video: {
            thumbnails_group_uuid: @file.video_thumbnails_group_uuid
          }
        }
      },
      relationships: {
        project: {
          data: { type: "projects", id: @file.project.uuid }
        }
      },
      authentication: {
        access_token: @file.access_token
      },
      multipart_upload_urls: @file.multipart_upload_urls.to_a
    }
  end
end
