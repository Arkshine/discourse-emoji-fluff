import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";
import { FLUFF_EMOJI_PICKER_ID } from "../lib/constants";

export default class FluffEmojiPicker extends Service {
  @service tooltip;

  @tracked enabled;
  @tracked selectedTarget;
  @tracked selectedEmoji;
  @tracked selectedFluff;

  @tracked lastSelectedEmoji;
  @tracked lastSelectedTarget;

  @tracked hoveredFluff;

  init() {
    super.init(...arguments);
    this.clear();
  }

  clear() {
    this.tooltip.close(FLUFF_EMOJI_PICKER_ID);

    this.enabled = false;
    this.selectedTarget = null;
    this.selectedEmoji = "";
    this.selectedFluff = "";

    this.lastSelectedEmoji = "";
    this.lastSelectedTarget = null;

    this.hoveredFluff = "";
  }
}
