import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import FluffToggleSwitch from "../components/fluff-toggle-switch";

export default class FluffEmojiPickerFilterContainer extends Component {
  @service fluffPresence;

  <template>
    {{#if this.fluffPresence.isPresent}}
      <FluffToggleSwitch
        @icon="wand-magic-sparkles"
        @title={{i18n (themePrefix "fluff_selector.toggle_switch.toggle")}}
      />
    {{/if}}
  </template>
}
