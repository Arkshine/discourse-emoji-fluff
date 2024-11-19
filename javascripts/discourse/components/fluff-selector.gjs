import Component from "@ember/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DTooltip from "discourse/components/d-tooltip";
import concatClass from "discourse/helpers/concat-class";
import dIcon from "discourse-common/helpers/d-icon";

export default class FluffSelector extends Component {
  @service tooltip;
  @service site;

  get allowedEffects() {
    return settings.allowed_effects.split("|");
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
  choosenFluff(effect) {
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
        class="btn btn-flat btn-fluff"
      >
        <:trigger>
          {{dIcon "wand-magic-sparkles"}}
        </:trigger>
        <:content>
          {{#each this.allowedEffects as |effect|}}
            <DButton
              @translatedTitle={{effect}}
              @action={{fn this.choosenFluff effect}}
              class="btn-transparent"
            >
              <img src={{@option.src}} class={{concatClass "emoji" effect}} />
            </DButton>
          {{/each}}
        </:content>
      </DTooltip>
    {{/if}}
  </template>
}
