import { action } from "@ember/object";
import { service } from "@ember/service";
import { isEmpty } from "@ember/utils";
import FluffSelector from "../components/fluff-selector";
import { FLUFF_EMOJI_PICKER_ID, FLUFF_PREFIX } from "./constants";

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

export function handleEmojiPicker(Superclass) {
  return class extends Superclass {
    @service fluffEmojiPicker;
    @service fluffPresence;
    @service tooltip;
    @service site;

    @action
    onClose(event) {
      if (!this.fluffPresence.isPresent) {
        return super.onClose(event);
      }

      if (
        this.fluffEmojiPicker.enabled &&
        this.fluffEmojiPicker.selectedEmoji &&
        !this.site.isMobileDevice
      ) {
        // Prevents the emoji picker from closing when clicking inside the tooltip.
        return false;
      }

      this.fluffEmojiPicker.clear();
      super.onClose(event);
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
  };
}
