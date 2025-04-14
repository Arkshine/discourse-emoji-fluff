import { setOwner } from "@ember/owner";
import { service } from "@ember/service";
import { withPluginApi } from "discourse/lib/plugin-api";
import FluffEmojiPickerFilterContainer from "../components/fluff-emoji-picker-filter-container";
import {
  //handleAutocomplete,
  //handleChatAutocomplete,
  //registerAutocompleteEvents,
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
  @service router;
  @service siteSettings;
  @service fluffPresence;

  constructor(owner, api) {
    setOwner(this, owner);

    if (
      !settings.allowed_decorations.length ||
      !this.siteSettings.enable_emoji
    ) {
      return;
    }

    if (api.decorateChatMessage) {
      //api.modifyClass("component:chat-composer", handleChatAutocomplete);
      api.decorateChatMessage(
        (element) => {
          if (settings.enabled) {
            renderFluff(element);
            applyEmojiOnlyClass(element);
          } else {
            removeFluff(element);
          }
        },
        {
          id: "fluff-emoji",
        }
      );
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

    this.updatePresence();

    if (!settings.enabled) {
      return;
    }

    if (this.allowSelectorInAutocomplete || this.allowSelectorInEmojiPicker) {
      if (this.allowSelectorInAutocomplete) {
        //api.modifyClass("component:d-editor", handleAutocomplete);
        //registerAutocompleteEvents();
      }

      if (this.allowSelectorInEmojiPicker) {
        api.modifyClass("component:emoji-picker/content", handleEmojiPicker);
        api.renderAfterWrapperOutlet(
          "emoji-picker-filter-container",
          FluffEmojiPickerFilterContainer
        );
      }
    }

    this.updateCSSProperty();
  }

  updatePresence() {
    this.router.on("routeDidChange", (transition) => {
      if (transition.isAborted) {
        return;
      }

      this.fluffPresence.setTo(
        settings.enabled &&
          transition.targetName &&
          ["discovery.", "topic.", "userPrivateMessages.user."].some(
            (partial) => transition.targetName.startsWith(partial)
          )
      );
    });
  }

  updateCSSProperty() {
    document
      .querySelector(":root")
      .style.setProperty(
        "--fluff-selector-columns",
        closestSquareGrid(settings.allowed_decorations.split("|").length)
          .columns
      );
  }

  get allowSelectorInAutocomplete() {
    return ["autocomplete", "both"].includes(settings.allow_selector_in);
  }

  get allowSelectorInEmojiPicker() {
    return ["emoji-picker", "both"].includes(settings.allow_selector_in);
  }

  teardown() {
    if (this.allowSelectorInEmojiPicker) {
      teardownAutocompleteEvents();
    }
  }
}

export default {
  name: "discourse-emoji-fluff",

  initialize(owner) {
    withPluginApi((api) => {
      this.instance = new EmojiFluffInit(owner, api);
    });
  },

  tearDown() {
    this.instance.teardown();
    this.instance = null;
  },
};
