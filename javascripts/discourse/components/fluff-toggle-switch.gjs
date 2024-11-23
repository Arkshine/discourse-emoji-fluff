import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import dIcon from "discourse-common/helpers/d-icon";
import actionFeedback from "../lib/action-feedback";

export default class FluffToggleSwitch extends Component {
  @service fluffEmojiPicker;

  @action
  toggle() {
    this.fluffEmojiPicker.enabled = !this.fluffEmojiPicker.enabled;

    actionFeedback({
      selectorClass: ".emoji-picker.opened .fluff-toggle-switch",
      messageKey: themePrefix(
        this.fluffEmojiPicker.enabled
          ? "fluff_selector.toggle_switch.enabled"
          : "fluff_selector.toggle_switch.disabled"
      ),
    });
  }

  <template>
    <DButton
      @class={{concatClass @class "btn-transparent fluff-toggle-switch"}}
      @action={{this.toggle}}
      @translatedTitle={{@title}}
    >
      {{dIcon
        @icon
        class=(concatClass
          "fluff-toggle-switch__icon"
          (if this.fluffEmojiPicker.enabled "--checked")
        )
      }}
    </DButton>
  </template>
}
