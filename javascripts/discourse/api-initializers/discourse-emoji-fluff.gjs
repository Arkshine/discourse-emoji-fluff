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

      api.modifyClass("component:emoji-picker", handleEmojiPicker);
      api.modifyClass("component:d-editor", handleAutocomplete);

      document
        .querySelector(":root")
        .style.setProperty(
          "--fluff-selector-columns",
          closestSquareGrid(allowedEffects.split("|").length).columns
        );

      registerAutocompleteEvents();
    });
  }

  teardown() {
    teardownAutocompleteEvents();
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
