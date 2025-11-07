import { escapeExpression } from "discourse/lib/utilities";
import FluffSelectorTooltip from "./fluff-selector-tooltip";

const FluffRenderEmojiAutocomplete = <template>
  <div class="autocomplete with-fluff ac-emoji">
    <ul>
      {{#each @options as |option|}}
        <li data-code={{escapeExpression option.code}}>
          <a href>
            {{#if option.src}}
              <img src={{option.src}} class="emoji" />
              <span class="emoji-shortname">{{escapeExpression
                  option.code
                }}</span>
            {{else}}
              {{escapeExpression option.label}}
            {{/if}}
          </a>
          <FluffSelectorTooltip @option={{option}} />
        </li>
      {{/each}}
    </ul>
  </div>
</template>;

export default FluffRenderEmojiAutocomplete;
