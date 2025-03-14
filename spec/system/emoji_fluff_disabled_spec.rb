# frozen_string_literal: true

RSpec.describe "Emoji Fluff Disabled", system: true do
  let!(:theme) { upload_theme_component }

  fab!(:topic)
  fab!(:post_1) { Fabricate(:post, raw: ":smile:", topic: topic, skip_validation: true) }

  fab!(:post_2) { Fabricate(:post, raw: ":smile:f-spin:", topic: topic, skip_validation: true) }

  fab!(:post_3) { Fabricate(:post, raw: ":smile:f-spin:text", topic: topic, skip_validation: true) }

  fab!(:post_4) do
    Fabricate(:post, raw: ":smile:f-spin: text", topic: topic, skip_validation: true)
  end

  fab!(:user) { Fabricate(:admin) }

  let(:composer) { PageObjects::Components::Composer.new }

  before do
    theme.update_setting(:enabled, false)
    theme.save!
  end

  before { sign_in user }

  it "removes fluff in post" do
    visit("/t/#{topic.id}")
    within(find("#post_1")) { expect(find(".cooked").text).to eq("") }
    within(find("#post_2")) { expect(find(".cooked").text).to eq("") }
    within(find("#post_3")) { expect(find(".cooked").text).to eq("text") }
    within(find("#post_4")) { expect(find(".cooked").text).to eq("text") }
  end
end
