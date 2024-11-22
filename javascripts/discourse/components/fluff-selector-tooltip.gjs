import Component from "@ember/component";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import DTooltip from "discourse/components/d-tooltip";
import dIcon from "discourse-common/helpers/d-icon";
import { bind } from "discourse-common/utils/decorators";
import { FLUFF_EMOJI_PICKER_ID } from "../services/fluff-emoji-picker";
import FluffSelector from "./fluff-selector";

export default class FluffSelectorTooltip extends Component {
  @service fluffSelection;
  @service site;

  init() {
    super.init();

    // This is a hack to prevent the parent item from being
    // clicked when the fluff selector is clicked.
    schedule("afterRender", () => {
      this.element?.parentElement.addEventListener(
        "click",
        this.onParentItemClick,
        { passive: true }
      );
    });
  }

  willDestroy() {
    this.element?.parentElement.removeEventListener(
      "click",
      this.onParentItemClick,
      { passive: true }
    );

    super.willDestroy();
  }

  get identifier() {
    return FLUFF_EMOJI_PICKER_ID;
  }

  @bind
  onParentItemClick(event) {
    event.stopImmediatePropagation();
    return false;
  }

  <template>
    {{#if @option.code}}
      <DTooltip
        @identifier={{this.identifier}}
        @placement="right"
        @interactive={{true}}
        @animated={{false}}
        class="btn btn-flat btn-fluff-selector"
      >
        <:trigger>
          {{dIcon "wand-magic-sparkles"}}
        </:trigger>
        <:content>
          <FluffSelector @data={{@option}} />
        </:content>
      </DTooltip>
    {{/if}}
  </template>
}
