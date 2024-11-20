import Component from "@ember/component";
import { concat, fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { eq } from "truth-helpers";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import replaceEmoji from "discourse/helpers/replace-emoji";

export default class FluffSelector extends Component {
  @service tooltip;
  @service site;
  @service fluffEmojiPicker;

  get allowedEffects() {
    return settings.allowed_effects.split("|");
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
  onMouseHover(effect) {
    this.fluffEmojiPicker.hoveredFluff = effect;
  }

  @action
  onMouseOut() {
    this.fluffEmojiPicker.hoveredTarget = null;
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

    const li = document.querySelector(
      `.autocomplete.with-fluff [data-code=${this.data.code}]`
    );

    if (li) {
      this.data.fluff = effect;
      this.tooltip.close("fluff-selector-dropdown");

      li.dispatchEvent(new CustomEvent("click"));
    }
  }

  <template>
    {{#each this.allowedEffects as |effect|}}
      <DButton
        @translatedTitle={{effect}}
        @action={{fn this.selectFluff effect}}
        class={{concatClass
          "btn-transparent btn-fluff"
          (if (eq this.fluffSelection.selectedFluff effect) "-selected")
        }}
        {{on "mouseover" (fn this.onMouseHover effect)}}
        {{on "mouseout" (fn this.onMouseOut effect)}}
      >
        {{#if @data.src}}
          <img src={{@data.src}} class={{concatClass "emoji" effect}} />
        {{else}}
          {{replaceEmoji (concat ":" @data.code ":") (hash class=effect)}}
        {{/if}}
      </DButton>
    {{/each}}
  </template>
}
