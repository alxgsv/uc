require "rails_helper"

RSpec.describe CdnController, type: :request do
  it "should redirect files" do
    file = Uc::File.create!(uuid: "123", project: Uc::Project.create!(uuid: "123"))
    get "/cdn/#{file.id}/lalala/hehehe"
    expect(response.status).to eq(302)
    expect(response.headers["location"]).to eq("https://ucarecdn.com/123/lalala/hehehe")
  end

  it "should redirect groups" do
    group = Uc::Group.create!(uuid: "123~2", file_ids: [1, 2], project: Uc::Project.create!(uuid: "123"))
    get "/cdn/#{group.id}/lalala/hehehe"
    expect(response.status).to eq(302)
    expect(response.headers["location"]).to eq("https://ucarecdn.com/123~2/lalala/hehehe")
  end
end
