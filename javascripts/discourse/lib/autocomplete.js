import { action } from "@ember/object";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import $ from "jquery";
import { emojiSearch, isSkinTonableEmoji } from "pretty-text/emoji";
import { translations } from "pretty-text/emoji/data";
import EmojiPickerDetached from "discourse/components/emoji-picker/detached";
import { SKIP } from "discourse/lib/autocomplete";
import { findRawTemplate } from "discourse/lib/raw-templates";
import { emojiUrlFor } from "discourse/lib/text";
import virtualElementFromTextRange from "discourse/lib/virtual-element-from-text-range";
import { waitForClosedKeyboard } from "discourse/lib/wait-for-keyboard";
import { i18n } from "discourse-i18n";
import { FLUFF_EMOJI_PICKER_ID, FLUFF_PREFIX } from "./constants";

function onItemMouseover(li, event) {
  // Close the tooltip if the last item is "more...".
  if (!li.dataset.code) {
    this.tooltip.close(FLUFF_EMOJI_PICKER_ID);
    this.fluffEmojiAutocomplete.opened = false;
    return;
  }

  if (
    // Selector is not opened first.
    !this.fluffEmojiAutocomplete.opened ||
    // Ignore the button.
    event.target.classList.contains("btn-fluff-selector") ||
    // Selector is already opened on this item.
    li.querySelector(".btn-fluff-selector.-expanded")
  ) {
    return;
  }

  const target = li.querySelector(".btn-fluff-selector");

  // Shows the tooltip on this item.
  target?.dispatchEvent(
    new MouseEvent("mousemove", {
      bubbles: true,
      cancelable: true,
    })
  );
}

function clickOutsideIntercept(event) {
  const target = event.target;

  if (target?.closest(`[data-identifier="${FLUFF_EMOJI_PICKER_ID}"]`)) {
    // Prevents the autocomplete from closing when clicking inside the tooltip.
    event.preventDefault();
    event.stopImmediatePropagation();
    return false;
  }
}

export function registerAutocompleteEvents() {
  window.addEventListener("click", clickOutsideIntercept);
}

export function teardownAutocompleteEvents() {
  window.removeEventListener("click", clickOutsideIntercept);
}

function emojiAutocomplete($textarea) {
  const chatContext = this.composerId === "channel-composer";
  const textManipulationOrTextarea = chatContext
    ? $textarea
    : this.textManipulation;

  textManipulationOrTextarea.autocomplete({
    template: findRawTemplate("fluff-selector-autocomplete"),
    key: ":",
    treatAsTextarea: chatContext,

    onRender: () => {
      if (!this.site.mobileView) {
        schedule("afterRender", () => {
          document
            .querySelectorAll(".autocomplete.with-fluff li")
            .forEach((li) => {
              li.addEventListener("mouseover", onItemMouseover.bind(this, li));
            });
        });
      }
    },

    afterComplete: (text, event) => {
      if (chatContext) {
        event.preventDefault();
        this.composer.textarea.value = text;
        this.composer.focus();
      } else {
        schedule(
          "afterRender",
          this.textManipulation,
          this.textManipulation.blurAndFocus
        );
      }

      if (!this.site.mobileView) {
        document
          .querySelectorAll(".autocomplete.with-fluff li")
          .forEach((li) => {
            li.removeEventListener("mouseover", onItemMouseover.bind(this, li));
          });
      }
    },

    onKeyUp: (text, cp) => {
      const matches =
        /(?:^|[\s.\?,@\/#!%&*;:\[\]{}=\-_()])(:(?!:).?[\w-]*:?(?!:)(?:t\d?)?:?) ?$/gi.exec(
          text.substring(0, cp)
        );

      if (matches && matches[1]) {
        return [matches[1]];
      }
    },

    transformComplete: async (v, event) => {
      if (v.code) {
        this.emojiStore.trackEmojiForContext(v.code, "topic");
        let code = `${v.code}:`;
        if (v.fluff) {
          code += `${FLUFF_PREFIX}${v.fluff}:`;
        }
        return code;
      } else {
        textManipulationOrTextarea.autocomplete({ cancel: true });

        const menuOptions = {
          identifier: "emoji-picker",
          component: EmojiPickerDetached,
          modalForMobile: true,
          data: {
            didSelectEmoji: (emoji) => {
              if (chatContext) {
                this.onSelectEmoji(emoji);
              } else {
                this.textManipulation.emojiSelected(emoji);
              }
            },
            term: v.term,
          },
        };

        let virtualElement;
        if (chatContext) {
          // Close the keyboard before showing the emoji picker
          // it avoids a whole range of bugs on iOS
          await waitForClosedKeyboard(this);
          virtualElement = virtualElementFromTextRange();
        } else {
          if (event instanceof KeyboardEvent) {
            // when user selects more by pressing enter
            virtualElement = virtualElementFromTextRange();
          } else {
            // when user selects more by clicking on it
            // using textarea as a fallback as it's hard to have a good position
            // given the autocomplete menu will be gone by the time we are here
            virtualElement = this.textManipulation.textarea;
          }
        }

        this.menuInstance = this.menu.show(virtualElement, menuOptions);
        return "";
      }
    },

    dataSource: (term) => {
      return new Promise((resolve) => {
        const full = `:${term}`;
        term = term.toLowerCase();

        if (chatContext) {
          // We need to avoid quick emoji autocomplete cause it can interfere with quick
          // typing, set minimal length to 2
          let minLength = Math.max(
            this.siteSettings.emoji_autocomplete_min_chars,
            2
          );

          if (term.length < minLength) {
            return resolve(SKIP);
          }

          // bypass :-p and other common typed smileys
          if (
            !term.match(
              /[^-\{\}\[\]\(\)\*_\<\>\\\/].*[^-\{\}\[\]\(\)\*_\<\>\\\/]/
            )
          ) {
            return resolve(SKIP);
          }
        } else {
          if (term.length < this.siteSettings.emoji_autocomplete_min_chars) {
            return resolve(SKIP);
          }
        }

        if (term === "") {
          const favorites = this.emojiStore.favoritesForContext(
            chatContext ? "chat" : "topic"
          );
          if (favorites.length) {
            return resolve(
              favorites
                .filter((f) => !this.site.denied_emojis?.includes(f))
                .slice(0, 5)
            );
          } else {
            return resolve(["slight_smile", "smile", "wink", "sunny", "blush"]);
          }
        }

        // note this will only work for emojis starting with :
        // eg: :-)
        const emojiTranslation = this.site.custom_emoji_translation || {};
        const allTranslations = Object.assign(
          {},
          translations,
          emojiTranslation
        );
        if (allTranslations[full]) {
          return resolve([allTranslations[full]]);
        }

        const emojiDenied = this.site.denied_emojis || [];
        const match = term.match(/^:?(.*?):t([2-6])?$/);
        if (match) {
          const name = match[1];
          const scale = match[2];

          if (isSkinTonableEmoji(name) && !emojiDenied.includes(name)) {
            if (scale) {
              return resolve([`${name}:t${scale}`]);
            } else {
              return resolve([2, 3, 4, 5, 6].map((x) => `${name}:t${x}`));
            }
          }
        }

        const options = emojiSearch(term, {
          maxResults: 5,
          diversity: this.emojiStore.diversity,
          exclude: emojiDenied,
        });

        return resolve(options);
      })
        .then((list) => {
          if (list === SKIP) {
            return [];
          }

          return list.map((code) => ({ code, src: emojiUrlFor(code) }));
        })
        .then((list) => {
          if (list.length) {
            list.push({ label: i18n("composer.more_emoji"), term });
          }
          return list;
        });
    },

    triggerRule: async () => !(await this.textManipulation?.inCodeBlock()),
  });
}

export function handleChatAutocomplete(Superclass) {
  return class extends Superclass {
    @service tooltip;
    @service fluffEmojiAutocomplete;
    @service fluffPresence;

    @action
    setupAutocomplete(textarea) {
      if (!this.siteSettings.enable_emoji || !this.fluffPresence.isPresent) {
        return super.setupAutocomplete(textarea);
      }

      this.siteSettings.enable_emoji = false;
      super.setupAutocomplete(textarea);
      this.siteSettings.enable_emoji = true;

      emojiAutocomplete.call(this, $(textarea));
    }
  };
}

export function handleAutocomplete(Superclass) {
  return class extends Superclass {
    @service tooltip;
    @service fluffEmojiAutocomplete;
    @service fluffPresence;

    _applyEmojiAutocomplete() {
      if (!this.siteSettings.enable_emoji || !this.fluffPresence.isPresent) {
        return super._applyEmojiAutocomplete();
      }

      emojiAutocomplete.call(this);
    }
  };
}
