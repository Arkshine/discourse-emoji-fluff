import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";

export default class FluffEmojiPicker extends Service {
  @service tooltip;

  @tracked enabled;
  @tracked selectedTarget;
  @tracked selectedEmoji;
  @tracked selectedFluff;
  @tracked hoveredFluff;

  init() {
    super.init(...arguments);
    this.clear();
  }

  clear() {
    this.enabled = false;
    this.selectedTarget = null;
    this.selectedEmoji = "";
    this.selectedFluff = "";
    this.hoveredFluff = "";
  }
}
