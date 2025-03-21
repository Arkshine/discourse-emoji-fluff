import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";

export default class FluffPresence extends Service {
  @tracked isPresent = false;

  setTo(value) {
    this.isPresent = value;
  }
}
