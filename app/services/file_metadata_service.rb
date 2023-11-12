class FileMetadataService
  def initialize(file)
    @file = file
  end

  def show(metadata)
    return {} if metadata.blank?

    metadata.stringify_keys.except("file_id")
  end

  def update(metadata)
    metadata = metadata.to_unsafe_h if metadata.is_a?(ActionController::Parameters)
    # Rewriting whole metadata
    if metadata.is_a?(Hash)
      current_metadata = Uploadcare::FileMetadata.index(@file.uuid).stringify_keys
      (current_metadata.keys - metadata.keys).each do |key|
        next if key == "file_id"

        Uploadcare::FileMetadata.delete(@file.uuid, key)
      end
      metadata.each do |key, value|
        next if current_metadata[key] == value
        next if key == "file_id"

        Uploadcare::FileMetadata.update(@file.uuid, key, value)
      end
    # Setting specific keys
    elsif metadata.is_a?(Array)
      metadata.each do |keyvalue|
        next if keyvalue[:key] == "file_id"

        Uploadcare::FileMetadata.update(@file.uuid, keyvalue[:key], keyvalue[:value])
      end
    end
  end
end
