import { schedule } from "@ember/runloop";
import { emojiSearch, isSkinTonableEmoji } from "pretty-text/emoji";
import { translations } from "pretty-text/emoji/data";
import { apiInitializer } from "discourse/lib/api";
import { SKIP } from "discourse/lib/autocomplete";
import { emojiUrlFor } from "discourse/lib/text";
import { findRawTemplate } from "discourse-common/lib/raw-templates";
import I18n from "discourse-i18n";

export default apiInitializer("1.8.0", (api) => {
  const allowedEffects = settings.allowed_effects;

  if (!allowedEffects.length) {
    return;
  }

  api.decorateCookedElement(
    (element /*, helper*/) => {
      const images = element.querySelectorAll("img");

      images.forEach((img) => {
        const nextSibling = img.nextSibling;

        if (nextSibling && nextSibling.nodeType === Node.TEXT_NODE) {
          const textContent = nextSibling.nodeValue;
          const firstWord = textContent.split(" ")[0];

          if (settings.allowed_effects.includes(firstWord)) {
            const span = document.createElement("span");
            span.className = `emoji-fluff-wrapper ${firstWord}`;

            img.parentNode.insertBefore(span, img);
            span.appendChild(img);

            const restOfText = textContent.slice(firstWord.length);

            if (restOfText.trim()) {
              nextSibling.nodeValue = restOfText;
            } else {
              nextSibling.remove();
            }
          }
        }
      });
    },
    { afterAdopt: true }
  );

  window.addEventListener("click", (event) => {
    const target = event.target;

    if (
      target?.parentElement?.dataset?.identifier === "fluff-selector-dropdown"
    ) {
      event.preventDefault();
      event.stopImmediatePropagation();
      return false;
    }
  });

  api.modifyClass(
    "component:d-editor",
    (Superclass) =>
      class extends Superclass {
        _applyEmojiAutocomplete() {
          if (!this.siteSettings.enable_emoji) {
            return;
          }

          this.textManipulation.autocomplete({
            template: findRawTemplate("fluff-selector-autocomplete"),
            key: ":",
            autoSelectFirstSuggestion: false,
            afterComplete: (text) => {
              this.set("value", text);
              schedule(
                "afterRender",
                this.textManipulation,
                this.textManipulation.blurAndFocus
              );
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
                const fluff = v.fluff || "";
                return `${v.code}:${fluff}`;
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

                if (
                  term.length < this.siteSettings.emoji_autocomplete_min_chars
                ) {
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
                      return resolve(
                        [2, 3, 4, 5, 6].map((x) => `${name}:t${x}`)
                      );
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

            triggerRule: async () =>
              !(await this.textManipulation.inCodeBlock()),
          });
        }
      }
  );
});
