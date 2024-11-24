# frozen_string_literal: true

RSpec.describe "Emoji Fluff", system: true do
  let!(:theme) { upload_theme_component }

  fab!(:topic_1) { Fabricate(:topic) }
  fab!(:post_1) do
    Fabricate(
      :post,
      raw:
        ":100: :100:f-spin:\n\n:balloon: :balloon: :balloon: :balloon:f-bounce:\n\n:+1: :+1:f-flip",
      topic: topic_1,
    )
  end

  fab!(:user) { Fabricate(:admin) }

  let(:composer) { PageObjects::Components::Composer.new }

  before { sign_in user }

  it "renders fluff in post" do
    visit("/t/#{topic_1.id}")

    expect(page).to have_css(".fluff.fluff--spin")
    expect(page).to have_css(".fluff.fluff--spin img.emoji")
    expect(page).to have_css(".fluff.fluff--spin img.emoji.only-emoji")
    expect(page).to have_no_css(".fluff.fluff--bounce img.emoji.only-emoji")
    expect(page).to have_no_css(".fluff.fluff--flip")
  end

  it "renders fluff in composer" do
    visit("/t/#{topic_1.id}")

    find(".post-controls .reply").click
    composer.fill_content(":smiley: :smile:f-spin:")

    within(".d-editor-preview") { find(".fluff.fluff--spin img.emoji") }
  end

  it "renders fluff selector in emoji autocomplete and adds a decoration" do
    visit("/t/#{topic_1.id}")

    find(".post-controls .reply").click
    composer.fill_content(":smile")
    expect(page).to have_css(".autocomplete.with-fluff .btn-fluff-selector")

    first(".autocomplete.with-fluff .btn-fluff-selector").click
    expect(page).to have_css(".fluff-selector-dropdown-content")
    expect(page).to have_css(".fluff-selector-dropdown-content .fluff")

    first(".fluff-selector-dropdown-content .fluff").click

    expect(find(".d-editor .d-editor-input").value).to eq(":smile:f-flip: ")
    expect(composer.preview).to have_css(".fluff.fluff--flip img.emoji")
    expect(page).to have_no_css("[data-identifier='fluff-selector-dropdown']")
  end

  it "renders fluff selector in emoji picker and adds a decoration" do
    visit("/t/#{topic_1.id}")

    find(".post-controls .reply").click
    first(".insert-emoji").click
    expect(page).to have_css(".emoji-picker.opened .fluff-toggle-switch")

    find(".emoji-picker.opened .fluff-toggle-switch").click
    first(".emoji-picker.opened .emojis-container .emoji[title='smile'").click

    expect(page).to have_css("[data-identifier='fluff-selector-dropdown']")
    first("[data-identifier='fluff-selector-dropdown'] .fluff").click
    expect(page).to have_css("[data-identifier='fluff-selector-dropdown']")

    expect(find(".d-editor .d-editor-input").value).to eq(":smile:f-flip:")
    expect(composer.preview).to have_css(".fluff.fluff--flip img.emoji")
  end
end
