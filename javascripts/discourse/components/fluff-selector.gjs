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

  get allowedEffects() {
    return settings.allowed_decorations.split("|");
  }

  get isEmojiPickerContext() {
    return this.data?.context === "emoji-picker";
  }

  get itemElement() {
    return document.querySelector(
      `.autocomplete.with-fluff [data-code="${this.data.code}"]`
    );
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
  onMouseHover(effect) {
    this.fluffEmojiPicker.hoveredFluff = effect;
  }

  @action
  onMouseOut() {
    this.fluffEmojiPicker.hoveredFluff = "";
    this.fluffEmojiPicker.selectedFluff = "";
  }

  @action
  selectFluff(effect) {
    if (this.isEmojiPickerContext) {
      this.fluffEmojiPicker.selectedFluff = effect;
      this.fluffEmojiPicker.selectedTarget?.dispatchEvent(
        new CustomEvent("click", {
          bubbles: true,
          cancelable: true,
        })
      );
      return;
    }

    const element = this.itemElement;

    if (element) {
      this.data.fluff = effect;
      this.tooltip.close(FLUFF_EMOJI_PICKER_ID);

      element.dispatchEvent(new CustomEvent("click"));
    }
  }

  <template>
    {{#each this.allowedEffects as |effect|}}
      <DButton
        @translatedTitle={{effect}}
        @action={{fn this.selectFluff effect}}
        class="btn-transparent btn-fluff-container"
        {{on "mouseover" (fn this.onMouseHover effect)}}
        {{on "mouseout" (fn this.onMouseOut effect)}}
      >
        <div class={{concatClass "fluff" (concat "fluff--" effect)}}>
          {{#if @data.src}}
            <img
              src={{@data.src}}
              class={{concatClass "emoji"}}
              title="effect"
            />
          {{else}}
            {{replaceEmoji (concat ":" @data.code ":") title=effect}}
          {{/if}}
        </div>
      </DButton>

    {{/each}}
  </template>
}
