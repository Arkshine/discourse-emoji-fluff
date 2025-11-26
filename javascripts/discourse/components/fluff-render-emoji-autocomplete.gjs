import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { escapeExpression } from "discourse/lib/utilities";
import { eq } from "discourse/truth-helpers";
import FluffSelectorTooltip from "./fluff-selector-tooltip";

export default class FluffRenderEmojiAutocomplete extends Component {
  @action
  handleResultClick(result, index, event) {
    event.preventDefault();
    event.stopPropagation();
    this.args.onSelect(result, index, event);
  }

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <div class="autocomplete with-fluff ac-emoji">
      <ul>
        {{#each @results as |result index|}}
          <li data-code={{escapeExpression result.code}} data-index={{@index}}>
            <a
              href
              class={{if (eq index @selectedIndex) "selected"}}
              {{on "click" (fn this.handleResultClick result index)}}
            >
              <span class="text-content">
                {{#if result.src}}
                  <img src={{result.src}} class="emoji" />
                  <span class="emoji-shortname">{{result.code}}</span>
                {{else}}
                  {{result.label}}
                {{/if}}
              </span>
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
