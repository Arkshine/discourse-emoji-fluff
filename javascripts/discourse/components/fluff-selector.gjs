import Component from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DMenu from "discourse/components/d-menu";
import DTooltip from "discourse/components/d-tooltip";
import DropdownMenu from "discourse/components/dropdown-menu";
import concatClass from "discourse/helpers/concat-class";

export default class FluffSelector extends Component {
  @service tooltip;

  get allowedEffects() {
    return settings.allowed_effects.split("|");
  }

  @action
  click(effect) {
    if (typeof effect !== "string") {
      return;
    }

    const li = this.element
      .closest(".fluff-emoji")
      .querySelector(`[data-code=${this.option.code}]`);

    if (li) {
      this.option.fluff = effect;
      this.tooltip.close("fluff-selector-dropdown");

      li?.dispatchEvent(new CustomEvent("click"));
    }
  }

  <template>
    {{#if @option.code}}
      <DTooltip
        @identifier="fluff-selector-dropdown"
        @placement="right"
        @interactive={{true}}
        @maxWidth="70"
        class="btn btn-flat btn-fluff"
      >
        <:trigger>
          🪄
        </:trigger>
        <:content>
          <DropdownMenu as |dropdown|>
            {{#each this.allowedEffects as |effect|}}
              <dropdown.item>
                <DButton
                  @translatedTitle={{effect}}
                  @action={{fn this.click effect}}
                  class={{"btn-transparent"}}
                >
                  <img
                    src={{@option.src}}
                    class={{concatClass "emoji" effect}}
                  />
                </DButton>
              </dropdown.item>
            {{/each}}
          </DropdownMenu>
        </:content>
      </DTooltip>
    {{/if}}
  </template>
}
