import { action } from "@ember/object";
import { service } from "@ember/service";
import FluffSelector from "../components/fluff-selector";
import { FLUFF_EMOJI_PICKER_ID, FLUFF_PREFIX } from "./constants";

export function handleEmojiPicker(Superclass) {
  return class extends Superclass {
    @service fluffEmojiPicker;
    @service fluffPresence;
    @service tooltip;
    @service site;

    willDestroy() {
      this.tooltip.close(FLUFF_EMOJI_PICKER_ID);
      this.fluffEmojiPicker.clear();
      super.willDestroy();
    }

    @action
    async didSelectEmoji(event) {
      if (
        !event.target.classList.contains("emoji") ||
        !(event.type === "click" || event.key === "Enter")
      ) {
        return super.didSelectEmoji(event);
      }

      if (
        !this.fluffPresence.isPresent ||
        !this.fluffEmojiPicker.enabled ||
        (this.fluffEmojiPicker.selectedEmoji &&
          !this.fluffEmojiPicker.selectedFluff)
      ) {
        if (
          // If we select too fastly an emoji, the tooltip close event is not called.
          // So, if the target is not the same, we reset.
          this.fluffEmojiPicker.selectedTarget &&
          !this.fluffEmojiPicker.selectedTarget.isSameNode(event.target)
        ) {
          this.fluffEmojiPicker.selectedEmoji = "";
          this.fluffEmojiPicker.selectedTarget = null;
        } else {
          return super.didSelectEmoji(event);
        }
      }

      event.preventDefault();
      event.stopPropagation();

      let emoji = event.target.dataset.emoji;
      const tonable = event.target.dataset.tonable;
      const diversity = this.emojiStore.diversity;

      if (tonable && diversity > 1) {
        emoji = `${emoji}:t${diversity}`;
      }

      if (!this.fluffEmojiPicker.selectedEmoji) {
        this.fluffEmojiPicker.selectedEmoji = emoji;
        this.fluffEmojiPicker.selectedTarget = event.target;

        this.tooltip.show(event.target, {
          component: FluffSelector,
          identifier: FLUFF_EMOJI_PICKER_ID,
          onClose: () => {
            this.fluffEmojiPicker.selectedEmoji = null;
            this.fluffEmojiPicker.selectedTarget = null;
          },
          data: {
            code: emoji,
            context: "emoji-picker",
          },
        });
      } else {
        this.emojiStore.trackEmojiForContext(emoji, this.args.context);

        this.args.didSelectEmoji?.(
          `${emoji}:${FLUFF_PREFIX}${this.fluffEmojiPicker.selectedFluff}`
        );

        await this.args.close?.();
      }
    }
  };
}
