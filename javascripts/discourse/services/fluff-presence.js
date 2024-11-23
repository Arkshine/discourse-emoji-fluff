import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";

export default class FluffPresence extends Service {
  @service router;
  @tracked isPresent;

  init() {
    super.init(...arguments);

    if (settings.enabled && this.router.currentRouteName.startsWith("topic.")) {
      this.setTo(true);
    }
  }

  setTo(value) {
    this.isPresent = value;
  }
}
