import DAutocompleteModifier from "discourse/modifiers/d-autocomplete";
import { VISIBILITY_OPTIMIZERS } from "float-kit/lib/constants";
import DAutocompleteResultsOverwrite from "../components/d-autocomplete-results-overwrite";

export default class DAutocompleteModifierOverwrite extends DAutocompleteModifier {
  static setupAutocompleteFluff(owner, element, autocompleteHandler, options) {
    const modifier = new DAutocompleteModifierOverwrite(owner, {
      named: {},
      positional: [],
    });

    const modifierOptions = {
      ...options,
      textHandler: autocompleteHandler,
    };

    modifier.modify(element, [modifierOptions]);
    return modifier;
  }

  async openAutocomplete() {
    this.pendingSpaceSearch = false;
    this.selectedIndex = this.autoSelectFirstSuggestion ? 0 : -1;
    try {
      // Create virtual element with appropriate positioning
      const virtualElement = this.options.fixedTextareaPosition
        ? this.createVirtualElementAtTextarea()
        : this.createVirtualElementAtCaret();

      const menuOptions = {
        identifier: "d-autocomplete",
        component: DAutocompleteResultsOverwrite,
        visibilityOptimizer: VISIBILITY_OPTIMIZERS.AUTO_PLACEMENT,
        placement: "top-start",
        allowedPlacements: [
          "top-start",
          "top-end",
          "bottom-start",
          "bottom-end",
        ],
        data: {
          getResults: () => this.results,
          getSelectedIndex: () => this.selectedIndex,
          onSelect: (result, index, event) => this.selectResult(result, event),
          template: this.options.template,
          component: this.options.component,
          onRender: this.options.onRender,
        },
        modalForMobile: false,
        onClose: () => {
          this.expanded = false;
          this.options.onClose?.();
        },
      };

      // Add offset if specified
      if (this.options.offset !== undefined) {
        menuOptions.offset = this.options.offset;
      }

      await this.menu.show(virtualElement, menuOptions);
      this.expanded = true;
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error("[autocomplete] renderAutocomplete: ", e);
    }
  }
}
