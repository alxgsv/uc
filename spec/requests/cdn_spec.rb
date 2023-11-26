require "rails_helper"

RSpec.describe CdnController, type: :request do
  it "should redirect files" do
    file = Uc::File.create!(uuid: "123", project: Uc::Project.create!(uuid: "123"), original_protected: false)
    get "/cdn/#{file.id}/lalala/hehehe"
    expect(response.status).to eq(302)
    expect(response.headers["location"]).to eq("https://ucarecdn.com/123/lalala/hehehe")
  end

  it "shouldn't deny access to derivatives" do
    file = Uc::File.create!(uuid: "123", project: Uc::Project.create!(uuid: "123"), original_protected: true)
    get "/cdn/#{file.id}/lalala/hehehe"
    expect(response.status).to eq(302)
    expect(response.headers["location"]).to eq("https://ucarecdn.com/123/lalala/hehehe")
  end

  it "should deny access to originals" do
    file = Uc::File.create!(uuid: "123", project: Uc::Project.create!(uuid: "123"), original_protected: true)
    get "/cdn/#{file.id}/"
    expect(response.status).to eq(404)
    get "/cdn/#{file.id}"
    expect(response.status).to eq(404)
  end

  it "should redirect groups" do
    group = Uc::Group.create!(uuid: "123~2", file_ids: [1, 2], project: Uc::Project.create!(uuid: "123"))
    get "/cdn/#{group.id}/lalala/hehehe"
    expect(response.status).to eq(302)
    expect(response.headers["location"]).to eq("https://ucarecdn.com/123~2/lalala/hehehe")
  end
end
