import { setOwner } from "@ember/application";
import { withPluginApi } from "discourse/lib/plugin-api";
import {
  handleAutocomplete,
  registerAutocompleteEvents,
  teardownAutocompleteEvents,
} from "../lib/autocomplete";
import { handleEmojiPicker } from "../lib/emoji-picker";
import {
  applyEmojiOnlyClass,
  removeFluff,
  renderFluff,
} from "../lib/render-fluff";
import { closestSquareGrid } from "../lib/utils";

class EmojiFluffInit {
  constructor(owner) {
    setOwner(this, owner);

    withPluginApi("1.32.0", (api) => {
      const allowedEffects = settings.allowed_effects;
      const siteSettings = api.container.lookup("service:site-settings");

      if (!allowedEffects.length || !siteSettings.enable_emoji) {
        return;
      }

      api.decorateCookedElement(
        (element) => {
          if (settings.enabled) {
            renderFluff(element);
            applyEmojiOnlyClass(element);
          } else {
            removeFluff(element);
          }
        },
        { afterAdopt: true }
      );

      if (!settings.enabled) {
        return;
      }

      const allowSelectorInAutocomplete = ["autocomplete", "both"].includes(
        settings.allow_selector_in
      );
      const allowSelectorInEmojiPicker = ["emoji-picker", "both"].includes(
        settings.allow_selector_in
      );

      if (allowSelectorInAutocomplete || allowSelectorInEmojiPicker) {
        if (allowSelectorInAutocomplete) {
          api.modifyClass("component:d-editor", handleAutocomplete);
        }

        if (allowSelectorInEmojiPicker) {
          api.modifyClass("component:emoji-picker", handleEmojiPicker);
        }
      }

      document
        .querySelector(":root")
        .style.setProperty(
          "--fluff-selector-columns",
          closestSquareGrid(allowedEffects.split("|").length).columns
        );

      if (allowSelectorInAutocomplete) {
        registerAutocompleteEvents();
      }
    });
  }

  teardown() {
    if (["autocomplete", "both"].includes(settings.allow_selector_in)) {
      teardownAutocompleteEvents();
    }
  }
}

export default {
  name: "discourse-emoji-fluff",

  initialize(owner) {
    this.instance = new EmojiFluffInit(owner);
  },

  tearDown() {
    this.instance.teardown();
    this.instance = null;
  },
};
