import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";

export default class FluffEmojiAutocomplete extends Service {
  @tracked opened;
}
