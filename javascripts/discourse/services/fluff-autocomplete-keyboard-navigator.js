import Service from "@ember/service";
import FluffKeyboardNavigator from "../lib/fluff-keyboard-navigator";

export default class FluffAutocompleteKeyboardNavigator extends Service {
  #navigator = null;

  init() {
    super.init(...arguments);
    this.#navigator = new FluffKeyboardNavigator();
  }

  get instance() {
    return this.#navigator;
  }

  addListener() {
    this.#navigator.addListener();
  }

  removeListener() {
    this.#navigator.removeListener();
  }

  setCloseCallback(callback) {
    this.#navigator.setCloseCallback(callback);
  }
}
