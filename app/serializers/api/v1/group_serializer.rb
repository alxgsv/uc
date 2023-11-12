class Api::V1::GroupSerializer
  def initialize(group, auth_token: nil)
    @group = group
    @uc_group = @group.uploadcare_show_response || (@group.uuid && Uploadcare::Group.rest_info(@group.uuid))
  end


  def serialize
    {
      type: :groups,
      id: @group.id,
      attributes: {
        uuid: @group.uuid,
        status: @group.status
      },
      relationships: {
        project: {
          data: { type: "projects", id: @group.project.uuid }
        }
      },
      authentication: {
        access_token: @group.access_token
      }
    }
  end
end
