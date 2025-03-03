import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import actionFeedback from "../lib/action-feedback";
import { FLUFF_EMOJI_PICKER_ID } from "../lib/constants";

export default class FluffToggleSwitch extends Component {
  @service fluffEmojiPicker;
  @service tooltip;

  @action
  toggle() {
    this.fluffEmojiPicker.enabled = !this.fluffEmojiPicker.enabled;

    if (!this.fluffEmojiPicker.enabled) {
      this.tooltip.close(FLUFF_EMOJI_PICKER_ID);
    }

    actionFeedback({
      selectorClass: ".emoji-picker .fluff-toggle-switch",
      messageKey: themePrefix(
        this.fluffEmojiPicker.enabled
          ? "fluff_selector.toggle_switch.enabled"
          : "fluff_selector.toggle_switch.disabled"
      ),
    });
  }

  <template>
    <DButton
      class={{concatClass @class "btn-transparent fluff-toggle-switch"}}
      @action={{this.toggle}}
      @translatedTitle={{@title}}
    >
      {{icon
        @icon
        class=(concatClass
          "fluff-toggle-switch__icon"
          (if this.fluffEmojiPicker.enabled "--checked")
        )
      }}
    </DButton>
  </template>
}
