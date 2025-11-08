import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import { emojiSearch, isSkinTonableEmoji } from "pretty-text/emoji";
import { translations } from "pretty-text/emoji/data";
import EmojiPickerDetached from "discourse/components/emoji-picker/detached";
import renderEmojiAutocomplete from "discourse/lib/autocomplete/emoji";
import loadEmojiSearchAliases from "discourse/lib/load-emoji-search-aliases";
import { emojiUrlFor } from "discourse/lib/text";
import virtualElementFromTextRange from "discourse/lib/virtual-element-from-text-range";
import { waitForClosedKeyboard } from "discourse/lib/wait-for-keyboard";
import {
  EMOJI_ALLOWED_PRECEDING_CHARS_REGEXP,
  SKIP,
} from "discourse/modifiers/d-autocomplete";
import { i18n } from "discourse-i18n";
import FluffRenderEmojiAutocomplete from "../components/fluff-render-emoji-autocomplete";
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

function overwriteChatEmojiAutocomplete(options) {
  options = {
    ...options,
    component: FluffRenderEmojiAutocomplete, // Fluff component
    afterComplete: (text, event) => {
      event.preventDefault();
      this.composer.textarea.value = text;
      this.composer.focus();

      document.querySelectorAll(".autocomplete.with-fluff li").forEach((li) => {
        li.addEventListener("mouseover", onItemMouseover.bind(this, li));
      });
    },
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
    transformComplete: async (v) => {
      if (v.code) {
        let code = `${v.code}:`;
        if (v.fluff) {
          code += `${FLUFF_PREFIX}${v.fluff}:`; // fluff
        }
        return code;
      } else {
        const menuOptions = {
          identifier: "emoji-picker",
          groupIdentifier: "emoji-picker",
          component: EmojiPickerDetached,
          context: "chat",
          modalForMobile: true,
          data: {
            didSelectEmoji: (emoji) => {
              this.onSelectEmoji(emoji);
            },
            term: v.term,
            context: "chat",
          },
        };

        // Close the keyboard before showing the emoji picker
        // it avoids a whole range of bugs on iOS
        await waitForClosedKeyboard(this);

        const virtualElement = virtualElementFromTextRange();
        this.menuInstance = await this.menu.show(virtualElement, menuOptions);
        return "";
      }
    },
  };

  return options;
}

function overwriteEmojiAutocomplete() {
  const options = {
    template: renderEmojiAutocomplete,
    component: FluffRenderEmojiAutocomplete, // Fluff component
    key: ":",
    afterComplete: () => {
      schedule(
        "afterRender",
        this.textManipulation,
        this.textManipulation.blurAndFocus
      );

      if (!this.site.mobileView) {
        document
          .querySelectorAll(".autocomplete.with-fluff li")
          .forEach((li) => {
            li.removeEventListener("mouseover", onItemMouseover.bind(this, li));
          });
      }
    },

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

    onKeyUp: (text, cp) => {
      const matches = new RegExp(
        `(?:^|${EMOJI_ALLOWED_PRECEDING_CHARS_REGEXP.source})(:(?!:).?[\\w-]*:?(?!:)(?:t\\d?)?:?) ?$`,
        "gi"
      ).exec(text.substring(0, cp));

      if (matches && matches[1]) {
        return [matches[1]];
      }
    },

    transformComplete: async (v) => {
      if (v.code) {
        this.emojiStore.trackEmojiForContext(v.code, "topic");
        let code = `${v.code}:`;
        if (v.fluff) {
          code += `${FLUFF_PREFIX}${v.fluff}:`; // fluff
        }
        return code;
      } else {
        this.textManipulation.autocomplete({ cancel: true });

        const menuOptions = {
          identifier: "emoji-picker",
          component: EmojiPickerDetached,
          modalForMobile: true,
          data: {
            didSelectEmoji: (emoji) => {
              this.textManipulation.emojiSelected(emoji);
            },
            term: v.term,
          },
        };

        const caretCoords =
          this.textManipulation.autocompleteHandler.getCaretCoords(
            this.textManipulation.autocompleteHandler.getCaretPosition()
          );

        const rect = document
          .querySelector(".d-editor-input")
          .getBoundingClientRect();

        const marginLeft = 18;
        const marginTop = 10;

        const virtualElement = {
          getBoundingClientRect: () => ({
            left: rect.left + caretCoords.left + marginLeft,
            top: rect.top + caretCoords.top + marginTop,
            width: 0,
            height: 0,
          }),
        };
        this.menuInstance = this.menu.show(virtualElement, menuOptions);
        return "";
      }
    },

    dataSource: (term) => {
      return new Promise((resolve) => {
        const full = `:${term}`;
        term = term.toLowerCase();

        if (term.length < this.siteSettings.emoji_autocomplete_min_chars) {
          return resolve(SKIP);
        }

        if (term === "") {
          const favorites = this.emojiStore.favoritesForContext("topic");
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
        const emojiTranslation =
          this.get("site.custom_emoji_translation") || {};
        const allTranslations = Object.assign(
          {},
          translations,
          emojiTranslation
        );
        if (allTranslations[full]) {
          return resolve([allTranslations[full]]);
        }

        const emojiDenied = this.get("site.denied_emojis") || [];
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

        loadEmojiSearchAliases().then((searchAliases) => {
          resolve(
            emojiSearch(term, {
              maxResults: 5,
              diversity: this.emojiStore.diversity,
              exclude: emojiDenied,
              searchAliases,
            })
          );
        });
      })
        .then((list) => {
          if (list === SKIP) {
            return [];
          }

          return list.map((code) => {
            return { code, src: emojiUrlFor(code) };
          });
        })
        .then((list) => {
          if (list.length) {
            list.push({ label: i18n("composer.more_emoji"), term });
          }
          return list;
        });
    },

    triggerRule: async () => !(await this.textManipulation.inCodeBlock()),
  };

  this.textManipulation.autocomplete(options);
}

export function handleChatAutocomplete(Superclass) {
  return class extends Superclass {
    @service tooltip;
    @service fluffEmojiAutocomplete;
    @service fluffPresence;

    applyAutocomplete(textarea, options) {
      if (!this.fluffPresence.isPresent) {
        return super.applyAutocomplete(textarea, options);
      }

      const newOptions = overwriteChatEmojiAutocomplete.call(this, options);
      return super.applyAutocomplete(textarea, newOptions);
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

      overwriteEmojiAutocomplete.call(this);
    }
  };
}
