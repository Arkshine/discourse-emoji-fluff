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

    i = 0

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
          p.revise(
            Discourse.system_user,
            { raw: text },
            bypass_bump: true,
            skip_revision: skip_revision,
          )
          putc "."
          i += 1
        rescue StandardError => e
          puts "\nFailed to remap post (topic_id: #{p.topic_id}, post_id: #{p.id})\n, error: #{e.message}"
        end
      end

    i
  end
end

desc "Clean emoji decorations from posts"
task "fluff:delete_all", %i[skip_revision] => [:environment] do |_, args|
  require "highline/import"

  args.with_defaults(skip_revision: true)
  skip_revision = args[:skip_revision]

  if skip_revision != "true" && skip_revision != "false"
    puts "ERROR: Expecting rake fluff:delete_all[skip_revision] where skip_revision is true or false"
    exit 1
  else
    confirm_replace = ask("Are you sure you want to remove any fluff decorations? (Y/n)")
    exit 1 unless (confirm_replace == "" || confirm_replace.downcase == "y")
  end

  puts "Deleting"
  total = EmojiFluffCleaner.clean(skip_revision: skip_revision == "true")
  puts "", "#{total} posts updated!", ""
end
