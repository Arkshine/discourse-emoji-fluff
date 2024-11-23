import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import { emojiSearch, isSkinTonableEmoji } from "pretty-text/emoji";
import { translations } from "pretty-text/emoji/data";
import { SKIP } from "discourse/lib/autocomplete";
import { emojiUrlFor } from "discourse/lib/text";
import { findRawTemplate } from "discourse-common/lib/raw-templates";
import I18n from "discourse-i18n";
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

  if (
    target?.classList.contains("fk-d-tooltip__inner-content") &&
    target?.closest(`[data-identifier="${FLUFF_EMOJI_PICKER_ID}"]`)
  ) {
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

export function handleAutocomplete(Superclass) {
  return class extends Superclass {
    @service tooltip;
    @service fluffEmojiAutocomplete;
    @service fluffPresence;

    _applyEmojiAutocomplete() {
      if (!this.siteSettings.enable_emoji || !this.fluffPresence.isPresent) {
        return super._applyEmojiAutocomplete();
      }

      this.textManipulation.autocomplete({
        template: findRawTemplate("fluff-selector-autocomplete"),
        key: ":",

        onRender: () => {
          if (!this.site.mobileView) {
            document
              .querySelectorAll(".autocomplete.with-fluff li")
              .forEach((li) => {
                li.addEventListener(
                  "mouseover",
                  onItemMouseover.bind(this, li)
                );
              });
          }
        },

        afterComplete: (text) => {
          this.set("value", text);
          schedule(
            "afterRender",
            this.textManipulation,
            this.textManipulation.blurAndFocus
          );

          if (!this.site.mobileView) {
            document
              .querySelectorAll(".autocomplete.with-fluff li")
              .forEach((li) => {
                li.removeEventListener(
                  "mouseover",
                  onItemMouseover.bind(this, li)
                );
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

        transformComplete: (v) => {
          if (v.code) {
            this.emojiStore.track(v.code);
            let code = `${v.code}:`;
            if (v.fluff) {
              code += `${FLUFF_PREFIX}${v.fluff}:`;
            }
            return code;
          } else {
            this.textManipulation.autocomplete({ cancel: true });
            this.set("emojiPickerIsActive", true);
            this.set("emojiFilter", v.term);

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
              if (this.emojiStore.favorites.length) {
                return resolve(
                  this.emojiStore.favorites
                    .filter((f) => !this.site.denied_emojis?.includes(f))
                    .slice(0, 5)
                );
              } else {
                return resolve([
                  "slight_smile",
                  "smile",
                  "wink",
                  "sunny",
                  "blush",
                ]);
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

              return list.map((code) => {
                return { code, src: emojiUrlFor(code) };
              });
            })
            .then((list) => {
              if (list.length) {
                list.push({ label: I18n.t("composer.more_emoji"), term });
              }
              return list;
            });
        },

        triggerRule: async () => !(await this.textManipulation.inCodeBlock()),
      });
    }
  };
}
