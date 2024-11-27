import Component from "@glimmer/component";
import { concat, fn } from "@ember/helper";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import replaceEmoji from "discourse/helpers/replace-emoji";
import i18n from "discourse-common/helpers/i18n";
import FluffToggleSwitch from "../components/fluff-toggle-switch";

export default class FluffEmojiPickerFooter extends Component {
  @service fluffPresence;
  @service fluffEmojiPicker;

  <template>
    <div
      class={{concatClass
        "emoji-picker-emoji-info"
        (concat
          (if this.fluffEmojiPicker.hoveredFluff "fluff--" "")
          this.fluffEmojiPicker.hoveredFluff
        )
      }}
    >
      {{#if this.fluffEmojiPicker.selectedEmoji}}
        {{replaceEmoji
          (concat ":" this.fluffEmojiPicker.selectedEmoji ":")
          title=this.fluffEmojiPicker.hoveredFluff
        }}
      {{else if @outletArgs.hoveredEmoji}}
        {{replaceEmoji (concat ":" @outletArgs.hoveredEmoji ":")}}
      {{/if}}
    </div>

    <div class="emoji-picker-diversity-picker">
      {{#each @outletArgs.diversityScales as |diversityScale index|}}
        <DButton
          @icon={{diversityScale.icon}}
          @title={{diversityScale.title}}
          @action={{fn @outletArgs.onDiversitySelection index}}
          class={{concatClass "diversity-scale" diversityScale.name}}
        />
      {{/each}}
    </div>

    {{#if this.fluffPresence.isPresent}}
      <FluffToggleSwitch
        @icon="wand-magic-sparkles"
        @title={{i18n (themePrefix "fluff_selector.toggle_switch.toggle")}}
      />
    {{/if}}
  </template>
}
