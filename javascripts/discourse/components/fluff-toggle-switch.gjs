import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import concatClass from "discourse/helpers/concat-class";
import dIcon from "discourse-common/helpers/d-icon";

export default class FluffToggleSwitch extends Component {
  @service fluffEmojiPicker;

  @action
  toggle(event) {
    this.fluffEmojiPicker.enabled = !this.fluffEmojiPicker.enabled;

    event.preventDefault();
    event.stopPropagation();
  }

  <template>
    <div
      class={{concatClass @class "simple-toggle-switch"}}
      {{on "click" this.toggle}}
    >
      {{dIcon
        @icon
        class=(concatClass
          "simple-toggle-switch__icon"
          (if this.fluffEmojiPicker.enabled "--checked")
        )
      }}
    </div>
  </template>
}
