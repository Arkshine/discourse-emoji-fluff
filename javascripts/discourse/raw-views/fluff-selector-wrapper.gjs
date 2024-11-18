import EmberObject from "@ember/object";
import rawRenderGlimmer from "discourse/lib/raw-render-glimmer";
import FluffSelector from "../components/fluff-selector";

export default class FluffSelectorWrapper extends EmberObject {
  get html() {
    return rawRenderGlimmer(
      this,
      "div.fluff-selector",
      <template><FluffSelector @option={{@data.option}} /></template>,
      { option: this.option }
    );
  }
}
