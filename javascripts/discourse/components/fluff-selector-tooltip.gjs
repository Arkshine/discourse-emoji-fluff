import Component from "@ember/component";
import { action } from "@ember/object";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import dIcon from "discourse/helpers/d-icon";
import { bind } from "discourse/lib/decorators";
import DTooltip from "float-kit/components/d-tooltip";
import { FLUFF_EMOJI_PICKER_ID } from "../lib/constants";
import FluffSelector from "./fluff-selector";

export default class FluffSelectorTooltip extends Component {
  @service fluffEmojiAutocomplete;
  @service fluffAutocompleteKeyboardNavigator;
  @service site;
  @service tooltip;

  eventsListeners = modifier((element) => {
    // This is a hack to prevent the parent item from being
    // clicked when the fluff button selector is clicked.
    schedule("afterRender", () => {
      element?.parentElement.addEventListener("click", this.onParentItemClick, {
        passive: true,
      });
    });

    return () =>
      element?.parentElement.removeEventListener(
        "click",
        this.onParentItemClick,
        { passive: true }
      );
  });

  get identifier() {
    return FLUFF_EMOJI_PICKER_ID;
  }

  get triggers() {
    return { mobile: ["click"], desktop: ["click", "hover"] };
  }

  get untriggers() {
    return { mobile: ["click"], desktop: ["hover"] };
  }

  @bind
  onParentItemClick(event) {
    event.stopImmediatePropagation();
    return false;
  }

  @action
  onShow() {
    this.fluffEmojiAutocomplete.opened = true;
    this.fluffAutocompleteKeyboardNavigator.setCloseCallback(() =>
      this.tooltip.close(FLUFF_EMOJI_PICKER_ID)
    );
  }

  @action
  onClose() {
    this.fluffEmojiAutocomplete.opened = false;
    this.fluffAutocompleteKeyboardNavigator.setCloseCallback(null);
  }

  <template>
    {{#if @option.code}}
      <DTooltip
        @identifier={{this.identifier}}
        @placement="right"
        @interactive={{true}}
        @animated={{false}}
        @onShow={{this.onShow}}
        @onClose={{this.onClose}}
        @triggers={{this.triggers}}
        @untriggers={{this.untriggers}}
        class="btn btn-transparent btn-fluff-selector"
        {{this.eventsListeners}}
      >
        <:trigger>
          {{dIcon "wand-magic-sparkles"}}
        </:trigger>
        <:content>
          <FluffSelector
            @data={{@option}}
            @selectedIndex={{@selectedIndex}}
            @onSelect={{@onSelect}}
            @onRender={{@onRender}}
          />
        </:content>
      </DTooltip>
    {{/if}}
  </template>
}
