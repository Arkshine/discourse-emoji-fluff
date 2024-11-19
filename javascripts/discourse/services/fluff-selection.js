import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";

export default class FluffSelection extends Service {
  @tracked fluffCode = "";

  update(value) {
    this.fluffCode = value;
  }

  clear() {
    this.update("");
  }

  get selected() {
    return this.fluffCode;
  }
}
