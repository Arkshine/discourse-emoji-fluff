# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
RSpec.describe "0001-rename-invert-in-allowed-decorations-setting migration" do
  let!(:theme) { upload_theme_component }

  it "should rename `invert` to `negative`" do
    theme.theme_settings.create!(
      name: "allowed_decorations",
      theme: theme,
      data_type: ThemeSetting.types[:string],
      value: "flip|flip_v|spin|pulse|bounce|wobble|float|slide|fade|invert|hue|gray",
    )

    run_theme_migration(theme, "0001-rename-invert-in-allowed-decorations-setting")

    expect(theme.settings[:allowed_decorations].value).to eq(
      "flip|flip_v|spin|pulse|bounce|wobble|float|slide|fade|negative|hue|gray",
    )
  end
end
