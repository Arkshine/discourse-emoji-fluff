# frozen_string_literal: true

RSpec.describe "Emoji Only Class", system: true do
  let!(:theme) { upload_theme_component }
  fab!(:user) { Fabricate(:admin) }
  let(:composer) { PageObjects::Components::Composer.new }

  before do
    theme.update_setting(:enabled, true)
    theme.save!
    sign_in user
  end

  context "when viewing posts" do
    SiteSetting.min_post_length = 1

    fab!(:topic)
    fab!(:post_single_emoji) do
      Fabricate(:post, raw: ":smile:", topic: topic, skip_validation: true)
    end

    fab!(:post_mixed_emojis) do
      Fabricate(:post, raw: ":smile: :heart:f-spin: :+1:", topic: topic, skip_validation: true)
    end

    fab!(:post_too_many_emojis) do
      Fabricate(
        :post,
        raw: ":smile:f-spin: :heart:f-spin: :+1:f-spin: :star:f-spin:",
        topic: topic,
        skip_validation: true,
      )
    end

    fab!(:post_with_text) do
      Fabricate(:post, raw: "Hello :smile: :heart:f-spin:", topic: topic, skip_validation: true)
    end

    fab!(:post_multiline) do
      Fabricate(
        :post,
        raw: "Hello world\n:smile: :heart:f-spin:\nMore text\n:star:",
        topic: topic,
        skip_validation: true,
      )
    end

    fab!(:post_single_with_line_break) do
      Fabricate(:post, raw: ":smile:f-bounce:\ntest", topic: topic, skip_validation: true)
    end

    it "applies only-emoji class to single emoji" do
      visit("/t/#{topic.id}/#{post_single_emoji.post_number}")
      within(find("#post_#{post_single_emoji.post_number}")) do
        expect(page).to have_css("img.emoji.only-emoji")
      end
    end

    it "applies only-emoji class to mixed regular and fluff emojis" do
      visit("/t/#{topic.id}/#{post_mixed_emojis.post_number}")
      within(find("#post_#{post_mixed_emojis.post_number}")) do
        expect(page).to have_css("img.emoji.only-emoji")
        expect(page).to have_css(".fluff img.emoji.only-emoji")
        expect(page).to have_css(".fluff.only-emoji")
      end
    end

    it "does not apply only-emoji class when more than 3 emojis" do
      visit("/t/#{topic.id}/#{post_too_many_emojis.post_number}")
      within(find("#post_#{post_too_many_emojis.post_number}")) do
        expect(page).to have_no_css(".only-emoji")
      end
    end

    it "does not apply only-emoji class when line contains text" do
      visit("/t/#{topic.id}/#{post_with_text.post_number}")
      within(find("#post_#{post_with_text.post_number}")) do
        expect(page).to have_no_css(".only-emoji")
      end
    end

    it "correctly handles multiline posts" do
      visit("/t/#{topic.id}/#{post_multiline.post_number}")

      within(find("#post_#{post_multiline.post_number}")) do
        expect(page).to have_css(".fluff.only-emoji")
      end
    end

    it "applies only-emoji class to emoji when separated by line break" do
      visit("/t/#{topic.id}/#{post_single_with_line_break.post_number}")

      within(find("#post_#{post_single_with_line_break.post_number}")) do
        expect(page).to have_css(".fluff.only-emoji")
      end
    end
  end

  context "when composing a post" do
    it "applies only-emoji class in preview when typing only emojis" do
      visit("/")
      find("#create-topic").click

      composer.fill_content(":smile: :heart:f-spin:")

      within(".d-editor-preview") do
        expect(page).to have_css("img.emoji.only-emoji")
        expect(page).to have_css(".fluff.only-emoji")
        expect(page).to have_css(".fluff img.emoji.only-emoji")
      end
    end

    it "does not apply only-emoji class in preview when mixing text and emojis" do
      visit("/")
      find("#create-topic").click

      composer.fill_content("Hello :smile: :heart:f-spin:")

      within(".d-editor-preview") { expect(page).to have_no_css(".only-emoji") }
    end

    xit "updates only-emoji class in preview when editing" do
      visit("/")
      find("#create-topic").click

      composer.fill_content(":smile: :heart:f-spin:")
      within(".d-editor-preview") { expect(page).to have_css(".only-emoji") }

      composer.fill_content(":smile: :heart:f-spin: hello")
      within(".d-editor-preview") { expect(page).to have_no_css(".only-emoji") }
    end
  end
end
