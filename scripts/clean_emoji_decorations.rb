#!/usr/bin/env ruby
# frozen_string_literal: true

module EmojiFluffCleaner
  def self.clean(skip_revision: false)
    fluff_regex =
      /(:[\w-]+(?:t\d{2,6})?):f-(?:flip|flip_v|spin|pulse|bounce|wobble|float|slide|fade|invert|hue|gray),?(?:flip|flip_v)*:/

    patterns = {
      INLINE: [%r{<code>[^<\n]+?</code>}],
      BLOCK: [
        /```[\s\S]*?```/m,
        /`[^`]*`/m,
        %r{<code>[\s\S]*?</code>}m,
        %r{<pre>[\s\S]*?</pre>}m,
        %r{\[code\][\s\S]*?\[/code\]}m,
        %r{\[pre\][\s\S]*?\[/pre\]}m,
      ],
    }

    Post
      .raw_match(fluff_regex.source, "regex")
      .find_each do |p|
        text, placeholders, counter = p.raw.dup, {}, 0

        patterns.each do |type, regex_list|
          regex_list.each do |regex|
            text.gsub!(regex) do |match|
              placeholder = "#{type}_CODE_#{counter += 1}_PLACEHOLDER"
              placeholders[placeholder] = match
              placeholder
            end
          end
        end

        placeholders.each { |ph, code| text.gsub!(ph, code) if ph.start_with?("INLINE") }
        text.gsub!(fluff_regex, '\1:')
        placeholders.each { |ph, code| text.gsub!(ph, code) if ph.start_with?("BLOCK") }

        next if text == p.raw

        begin
          p.revise(Discourse.system_user, { raw: text }, bypass_bump: true, skip_revision: skip_revision)
          putc "."
        rescue StandardError => e
          puts "\nFailed to remap post (topic_id: #{p.topic_id}, post_id: #{p.id})\n, error: #{e.message}"
        end
      end
  end
end

if __FILE__ == $0
  require_relative "../config/environment"
  require 'optparse'

  options = { skip_revision: false }
  OptionParser.new do |opts|
    opts.banner = "Usage: clean_emoji_decorations.rb [options]"

    opts.on("--skip-revision", "Skip revision") do
      options[:skip_revision] = true
    end
  end.parse!

  EmojiFluffCleaner.clean(skip_revision: options[:skip_revision])
end
