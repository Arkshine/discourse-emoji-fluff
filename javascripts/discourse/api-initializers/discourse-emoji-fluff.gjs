import { action } from "@ember/object";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import { isEmpty } from "@ember/utils";
import { emojiSearch, isSkinTonableEmoji } from "pretty-text/emoji";
import { translations } from "pretty-text/emoji/data";
import { apiInitializer } from "discourse/lib/api";
import { SKIP } from "discourse/lib/autocomplete";
import { emojiUrlFor } from "discourse/lib/text";
import { findRawTemplate } from "discourse-common/lib/raw-templates";
import I18n from "discourse-i18n";
import FluffSelector from "../components/fluff-selector";
import { FLUFF_EMOJI_PICKER_ID } from "../services/fluff-emoji-picker";

const FLUFF_PREFIX = "f-";

export default apiInitializer("1.8.0", (api) => {
  const allowedEffects = settings.allowed_effects;

  if (!allowedEffects.length) {
    return;
  }

  const siteSettings = api.container.lookup("service:site-settings");

  if (!siteSettings.enable_emoji) {
    return;
  }

  api.decorateCookedElement(
    (element /*, helper*/) => {
      const images = element.querySelectorAll("img.emoji");

      images.forEach((img) => {
        const nextSibling = img.nextSibling;

        if (nextSibling && nextSibling.nodeType === Node.TEXT_NODE) {
          const textContent = nextSibling.nodeValue;

          const result = /^(?<effect>[^:]+):/.exec(textContent);
          const effect = result?.groups?.effect;

          if (!effect || !effect.startsWith(FLUFF_PREFIX)) {
            return;
          }

          const effectWithoutPrefix = effect.replace(FLUFF_PREFIX, "");
          const restOfText = effect
            ? textContent.slice(effect.length + 1)
            : textContent;

          if (
            effectWithoutPrefix &&
            settings.allowed_effects.includes(effectWithoutPrefix)
          ) {
            const span = document.createElement("span");
            span.className = `emoji-fluff-wrapper fluff--${effectWithoutPrefix}`;
            img.parentNode.insertBefore(span, img);
            span.appendChild(img);

            if (restOfText) {
              nextSibling.nodeValue = restOfText;
            } else {
              nextSibling.remove();
            }
          }
        }
      });

      const paragraphs = element.querySelectorAll("p");

      paragraphs.forEach((paragraph) => {
        const children = Array.from(paragraph.childNodes);
        let emojiGroup = [];
        let validLine = true;

        children.forEach((node, index) => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            const isWrapperEmoji =
              node.matches("span.emoji-fluff-wrapper") &&
              node.querySelector("img.emoji");
            const isDirectEmoji = node.matches("img.emoji");

            if (isWrapperEmoji || isDirectEmoji) {
              emojiGroup.push(node);
            } else if (!node.matches("br")) {
              validLine = false;
            }
          } else if (node.nodeType === Node.TEXT_NODE) {
            if (node.nodeValue.trim() !== "") {
              validLine = false;
            }
          }

          const nextNode = children[index + 1];

          if (
            emojiGroup.length >= 1 &&
            validLine &&
            (!nextNode ||
              (nextNode.nodeType === Node.ELEMENT_NODE &&
                nextNode.matches("br")))
          ) {
            let spaceCount = 0;

            for (
              let i = Math.max(0, index - emojiGroup.length);
              i < index;
              i++
            ) {
              const child = children[i];
              if (
                child.nodeType === Node.TEXT_NODE &&
                child.nodeValue === " "
              ) {
                spaceCount++;
              }
            }

            if (spaceCount >= emojiGroup.length - 1) {
              const hasWrapperEmoji = emojiGroup.some((e) =>
                e.matches("span.emoji-fluff-wrapper")
              );
              const allDirectEmoji = emojiGroup.every((e) =>
                e.matches("img.emoji")
              );

              if (hasWrapperEmoji || !allDirectEmoji) {
                emojiGroup.forEach((emoji) => {
                  emoji.classList.add("only-emoji");
                  if (emoji.matches("span.emoji-fluff-wrapper")) {
                    emoji
                      .querySelector("img.emoji")
                      ?.classList.add("only-emoji");
                  }
                });
              }
            }

            emojiGroup = [];
            validLine = true;
          } else if (!validLine || (!nextNode && emojiGroup.length < 1)) {
            emojiGroup = [];
            validLine = true;
          }
        });
      });
    },
    { afterAdopt: true }
  );

  function closestSquareGrid(elements) {
    const dimension = Math.ceil(Math.sqrt(elements));
    let rows = dimension;
    let columns = dimension;

    while (rows * columns < elements.length) {
      if (rows <= columns) {
        rows++;
      } else {
        columns++;
      }
    }

    return { rows, columns };
  }

  document
    .querySelector(":root")
    .style.setProperty(
      "--fluff-selector-columns",
      closestSquareGrid(allowedEffects.split("|").length).columns
    );

  function emojiSelectedWitFluff(code, fluff) {
    let selected = this.getSelected();
    const captures = selected.pre.match(/\B:(\w*)$/);

    if (isEmpty(captures)) {
      if (selected.pre.match(/\S$/)) {
        this.addText(selected, ` :${code}:${FLUFF_PREFIX}${fluff}:`);
      } else {
        this.addText(selected, `:${code}:${FLUFF_PREFIX}${fluff}:`);
      }
    } else {
      let numOfRemovedChars = captures[1].length;
      this._insertAt(
        selected.start - numOfRemovedChars,
        selected.end,
        `${code}:${FLUFF_PREFIX}${fluff}:`
      );
    }
  }

  api.modifyClass(
    "component:emoji-picker",
    (Superclass) =>
      class extends Superclass {
        @service fluffEmojiPicker;
        @service fluffPresence;
        @service tooltip;
        @service site;

        @action
        onClose(event) {
          if (!this.fluffPresence.isPresent) {
            super.onClose(event);
            return;
          }

          if (
            !(
              this.fluffEmojiPicker.enabled &&
              this.fluffEmojiPicker.selectedEmoji &&
              !this.site.isMobileDevice
            )
          ) {
            super.onClose(event);
          }

          this.fluffEmojiPicker.clear();
        }

        @action
        onEmojiSelection(event) {
          if (
            !this.fluffPresence.isPresent ||
            !this.fluffEmojiPicker.enabled ||
            (this.fluffEmojiPicker.selectedEmoji &&
              !this.fluffEmojiPicker.selectedFluff)
          ) {
            return super.onEmojiSelection(event);
          }

          const img = event.target;

          if (!img.classList.contains("emoji") || img.tagName !== "IMG") {
            return false;
          }

          if (!this.fluffEmojiPicker.selectedEmoji) {
            let code = event.target.title;
            code = this._codeWithDiversity(code, this.selectedDiversity);

            this.fluffEmojiPicker.selectedEmoji = code;
            this.fluffEmojiPicker.selectedTarget = event.target;

            this.tooltip.show(event.target, {
              component: FluffSelector,
              identifier: FLUFF_EMOJI_PICKER_ID,
              onClose: () => {
                this.fluffEmojiPicker.selectedEmoji = null;
                this.fluffEmojiPicker.selectedTarget = null;
              },
              data: {
                code,
                context: "emoji-picker",
              },
            });
          } else {
            emojiSelectedWitFluff.call(
              this.parentView.textManipulation,
              this.fluffEmojiPicker.selectedEmoji,
              this.fluffEmojiPicker.selectedFluff
            );

            this._trackEmojiUsage(this.fluffEmojiPicker.selectedEmoji, {
              refresh: !img.parentNode.parentNode.classList.contains("recent"),
            });

            if (this.site.isMobileDevice) {
              this.onClose(event);
            }
          }

          return false;
        }
      }
  );

  function clickOutsideIntercept(event) {
    const target = event.target;

    if (
      target?.parentElement?.parentElement?.dataset?.identifier ===
      FLUFF_EMOJI_PICKER_ID
    ) {
      event.preventDefault();
      event.stopImmediatePropagation();
      return false;
    }
  }

  window.addEventListener("click", clickOutsideIntercept);

  api.modifyClass(
    "component:d-editor",
    (Superclass) =>
      class extends Superclass {
        @service tooltip;
        @service fluffEmojiAutocomplete;
        @service fluffPresence;

        _applyEmojiAutocomplete() {
          if (!this.siteSettings.enable_emoji) {
            return;
          }

          if (!this.fluffPresence.isPresent) {
            super._applyEmojiAutocomplete();
            return;
          }

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
