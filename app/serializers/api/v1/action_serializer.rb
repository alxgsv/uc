class Api::V1::ActionSerializer
  def initialize(action)
    @action = action
  end


  def serialize
    {
      type: :actions,
      id: @action.id,
      attributes: {
        action_type: @action.action_type,
        status: @action.status,
        result: @action.result
      },
      relationships: {
        project: {
          data: { type: "projects", id: @action.project.uuid }
        },
        file: {
          data: { type: "files", id: @action.file_id }
        },
      }
    }
  end
end
