import Component from "@ember/component";
import { service } from "@ember/service";
import DTooltip from "discourse/components/d-tooltip";
import dIcon from "discourse-common/helpers/d-icon";
import FluffSelector from "./fluff-selector";

export default class FluffSelectorTooltip extends Component {
  @service fluffSelection;

  get isEmojiPickerContext() {
    return this.option?.context === "emoji-picker";
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
        </:trigger>
        <:content>
          <FluffSelector @data={{@option}} />
        </:content>
      </DTooltip>
    {{/if}}
  </template>
}
