import { on } from "@ember/modifier";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import DAutocompleteResults from "discourse/components/d-autocomplete-results";

export default class DAutocompleteResultsOverwrite extends DAutocompleteResults {
  <template>
    <div
      {{didInsert this.handleInitialRender}}
      {{didUpdate this.handleUpdate this.selectedIndex this.templateHTML}}
      {{on "click" this.handleClick}}
      tabindex="-1"
    >
      {{#if @data.component}}
        <@data.component @options={{this.results}} />
      {{else}}
        {{this.templateHTML}}
      {{/if}}
    </div>
  </template>
}
