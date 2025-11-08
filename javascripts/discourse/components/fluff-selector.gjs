import Component from "@ember/component";
import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import replaceEmoji from "discourse/helpers/replace-emoji";
import { FLUFF_EMOJI_PICKER_ID } from "../lib/constants";

export default class FluffSelector extends Component {
  @service tooltip;
  @service site;
  @service fluffEmojiPicker;

  get allowedDecorations() {
    return settings.allowed_decorations.split("|");
  }

  get isEmojiPickerContext() {
    return this.data?.context === "emoji-picker";
  }

  @action
  click(event) {
    if (!this.site.mobileView) {
      return;
    }

    event.preventDefault();
    event.stopImmediatePropagation();
  }

  @action
  onMouseHover(decoration) {
    this.fluffEmojiPicker.hoveredFluff = decoration;
  }

  @action
  onMouseOut() {
    this.fluffEmojiPicker.hoveredFluff = "";
    this.fluffEmojiPicker.selectedFluff = "";
  }

  @action
  selectFluff(decoration, _, event) {
    if (this.isEmojiPickerContext) {
      this.fluffEmojiPicker.selectedFluff = decoration;
      this.fluffEmojiPicker.selectedTarget?.dispatchEvent(
        new CustomEvent("click", {
          bubbles: true,
          cancelable: true,
        })
      );

      this.tooltip.close(FLUFF_EMOJI_PICKER_ID);
      return;
    }

    const index = Array.from(
      document.querySelectorAll(".autocomplete.with-fluff li")
    ).findIndex((el) => el.dataset.code === this.data.code);

    if (index >= 0) {
      this.data.fluff = decoration;
      this.tooltip.close(FLUFF_EMOJI_PICKER_ID);
      this.onSelect(this.data, index, event);
    }
  }

  <template>
    <div class="fluff-selector-keyboard-container">
      {{#each this.allowedDecorations as |decoration|}}
        <DButton
          @translatedTitle={{decoration}}
          @action={{fn this.selectFluff decoration}}
          @forwardEvent={{true}}
          class="btn-transparent btn-fluff-container"
          {{on "mouseover" (fn this.onMouseHover decoration)}}
          {{on "mouseout" (fn this.onMouseOut decoration)}}
          tabindex="0"
        >
          <div class={{concatClass "fluff" (concat "fluff--" decoration)}}>
            {{#if @data.src}}
              <img
                src={{@data.src}}
                class={{concatClass "emoji"}}
                title={{decoration}}
              />
            {{else}}
              {{replaceEmoji (concat ":" @data.code ":") title=decoration}}
            {{/if}}
          </div>
        </DButton>

      {{/each}}
    </div>
  </template>
}
