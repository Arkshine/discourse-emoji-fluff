import Component from "@ember/component";
import { concat, fn, hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { and, eq } from "truth-helpers";
import DButton from "discourse/components/d-button";
import DTooltip from "discourse/components/d-tooltip";
import concatClass from "discourse/helpers/concat-class";
import replaceEmoji from "discourse/helpers/replace-emoji";
import dIcon from "discourse-common/helpers/d-icon";

export default class FluffSelector extends Component {
  @service tooltip;
  @service site;
  @service fluffSelection;

  get allowedEffects() {
    return settings.allowed_effects.split("|");
  }

  get isEmojiPickerContext() {
    return this.option?.context === "emoji-picker";
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
  selectFluff(effect) {
    if (this.isEmojiPickerContext) {
      this.fluffSelection.update(
        this.fluffSelection.selected === effect ? "" : effect
      );
      return;
    }

    const li = this.element
      .closest(".fluff-emoji")
      .querySelector(`[data-code=${this.option.code}]`);

    if (li) {
      this.option.fluff = effect;
      this.tooltip.close("fluff-selector-dropdown");

      li.dispatchEvent(new CustomEvent("click"));
    }
  }

  <template>
    {{#if @option.code}}
      <DTooltip
        @identifier="fluff-selector-dropdown"
        @placement="right"
        @interactive={{true}}
        @animated={{false}}
        class="btn btn-flat btn-fluff-selector"
      >
        <:trigger>
          {{dIcon "wand-magic-sparkles"}}
          {{#if (and this.fluffSelection.selected this.isEmojiPickerContext)}}
            {{dIcon "circle" class="fluff-selected"}}
          {{/if}}
        </:trigger>
        <:content>
          {{#each this.allowedEffects as |effect|}}
            <DButton
              @translatedTitle={{effect}}
              @action={{fn this.selectFluff effect}}
              class={{concatClass
                "btn-transparent btn-fluff"
                (if (eq this.fluffSelection.selected effect) "-selected")
              }}
            >
              {{#if @option.src}}
                <img src={{@option.src}} class={{concatClass "emoji" effect}} />
              {{else}}
                {{replaceEmoji
                  (concat ":" @option.code ":")
                  (hash class=effect)
                }}
              {{/if}}
            </DButton>
          {{/each}}
        </:content>
      </DTooltip>
    {{/if}}
  </template>
}
