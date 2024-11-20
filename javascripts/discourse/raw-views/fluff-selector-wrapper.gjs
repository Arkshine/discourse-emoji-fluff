import EmberObject from "@ember/object";
import rawRenderGlimmer from "discourse/lib/raw-render-glimmer";
import FluffSelectorTooltip from "../components/fluff-selector-tooltip";

export default class FluffSelectorWrapper extends EmberObject {
  get html() {
    return rawRenderGlimmer(
      this,
      "div.fluff-selector",
      <template><FluffSelectorTooltip @option={{@data.option}} /></template>,
      { option: this.option }
    );
  }
}
