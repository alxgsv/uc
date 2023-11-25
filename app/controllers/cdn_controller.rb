class CdnController < ApplicationController
  def show
    if file = request.path.match(/\/(f-[^\/]+)\//)
      file_id = file[1]
      file = Uc::File.find(file_id)

      if file.protect_original && !authenticated_user?
        raise ActiveRecord::RecordNotFound
      end

      uuid = Uc::File.find(file_id).uuid
      redirect_to "https://ucarecdn.com/#{ request.path.sub(/\/cdn/, "").sub(/\/#{file_id}/, uuid) }", allow_other_host: true and return
    elsif group = request.path.match(/\/(g-[^\/]+)\//)
      group_id = group[1]
      uuid = Uc::Group.find(group_id).uuid
      redirect_to "https://ucarecdn.com/#{ request.path.sub(/\/cdn/, "").sub(/\/#{group_id}/, uuid) }", allow_other_host: true and return
    end
    render :nothing => true
  end
end
