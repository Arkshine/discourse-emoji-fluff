import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { escapeExpression } from "discourse/lib/utilities";
import scrollIntoView from "discourse/modifiers/scroll-into-view";
import FluffSelectorTooltip from "./fluff-selector-tooltip";

const RESULT_ITEM_SELECTOR = "li a";
const SELECTED_CLASS = "selected";

export default class FluffRenderEmojiAutocomplete extends Component {
  @tracked isInitialRender = true;

  @action
  handleInsert() {
    this.args.onRender(this.args.results);
  }

  @action
  handleUpdate() {
    this.isInitialRender = false;
    this.args.onRender(this.args.results);
  }

  @action
  shouldScroll(index) {
    return index === this.args.selectedIndex && !this.isInitialRender;
  }

  @action
  shouldSelect(index) {
    return index === this.args.selectedIndex;
  }

  @action
  handleClick(event) {
    try {
      event.preventDefault();
      event.stopPropagation();

      const clickedLink = event.target.closest(RESULT_ITEM_SELECTOR);
      if (!clickedLink) {
        return;
      }

      // Find the index of the clicked link
      const links = event.currentTarget.querySelectorAll(RESULT_ITEM_SELECTOR);
      const index = Array.from(links).indexOf(clickedLink);

      if (index >= 0) {
        // Call onSelect and handle any promise returned
        const result = this.args.onSelect(
          this.args.results[index],
          index,
          event
        );
        if (result && typeof result.then === "function") {
          result.catch((e) => {
            // eslint-disable-next-line no-console
            console.error("[autocomplete] onSelect promise rejected: ", e);
          });
        }
      }
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error("[autocomplete] Click handler error: ", e);
    }
  }

  @action
  getItemLinkClasses(index) {
    let classes = [];

    if (this.shouldSelect(index)) {
      classes.push(SELECTED_CLASS);
    }

    return classes.join(" ");
  }

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <div
      class="autocomplete with-fluff ac-emoji"
      {{on "click" this.handleClick}}
      {{didInsert this.handleInsert}}
      {{didUpdate this.handleUpdate @selectedIndex}}
    >
      <ul>
        {{#each @results as |result index|}}
          <li
            data-code={{escapeExpression result.code}}
            data-index={{@index}}
            {{scrollIntoView (this.shouldScroll index)}}
          >
            <a href class={{this.getItemLinkClasses index}}>
              {{#if result.src}}
                <img src={{result.src}} class="emoji" />
                <span class="emoji-shortname">{{escapeExpression
                    result.code
                  }}</span>
              {{else}}
                {{escapeExpression result.label}}
              {{/if}}
            </a>
            <FluffSelectorTooltip
              @option={{result}}
              @onSelect={{@onSelect}}
              @selectedIndex={{@selectedIndex}}
              @onRender={{@onRender}}
            />
          </li>
        {{/each}}
      </ul>
    </div>
  </template>
}
