import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";

export default class FluffEmojiPicker extends Service {
  @tracked enabled = false;
  @tracked selectedTarget = null;
  @tracked selectedEmoji = "";
  @tracked selectedFluff = "";
  @tracked hoveredFluff = "";

  clear() {
    this.selectedTarget = null;
    this.selectedEmoji = "";
    this.selectedFluff = "";
    this.hoveredFluff = "";
  }
}
