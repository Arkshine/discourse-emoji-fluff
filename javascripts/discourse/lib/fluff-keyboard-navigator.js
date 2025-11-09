import { next, schedule } from "@ember/runloop";
import { FLUFF_EMOJI_PICKER_ID } from "./constants";
import { closestSquareGrid } from "./utils";

export default class FluffKeyboardNavigator {
  constructor() {
    this.currentIndex = 0;
    this.listenerAdded = false;
    this.gridDimensions = null;
    this.closeCallback = null;
  }

  setCloseCallback(callback) {
    this.closeCallback = callback;
  }

  getFluffSelector() {
    return document.querySelector(
      `[data-identifier="${FLUFF_EMOJI_PICKER_ID}"][data-content]`
    );
  }

  isFocusInFluffSelector() {
    return document.activeElement?.closest(
      `[data-identifier="${FLUFF_EMOJI_PICKER_ID}"][data-content]`
    );
  }

  calculateGridDimensions(buttonsCount) {
    return closestSquareGrid(buttonsCount);
  }

  highlightButton(buttons, index) {
    buttons.forEach((btn) => btn.classList.remove("keyboard-focused"));
    if (buttons[index]) {
      buttons[index].classList.add("keyboard-focused");
      buttons[index].focus();
      this.currentIndex = index;
    }
  }

  navigateGrid(direction, buttons) {
    if (!this.gridDimensions) {
      this.gridDimensions = this.calculateGridDimensions(buttons.length);
    }

    const { columns } = this.gridDimensions;
    const total = buttons.length;
    let newIndex = this.currentIndex;

    switch (direction) {
      case "right":
        newIndex = (this.currentIndex + 1) % total;
        break;
      case "left":
        newIndex = (this.currentIndex - 1 + total) % total;
        break;
      case "down":
        newIndex = this.currentIndex + columns;
        if (newIndex >= total) {
          newIndex = this.currentIndex % columns; // top
        }
        break;
      case "up":
        newIndex = this.currentIndex - columns;
        if (newIndex < 0) {
          const column = this.currentIndex % columns;
          const lastRowStart = Math.floor((total - 1) / columns) * columns;
          newIndex = lastRowStart + column;
          if (newIndex >= total) {
            newIndex -= columns; // previous row
          }
        }
        break;
    }

    this.highlightButton(buttons, newIndex);
  }

  closeFluffSelector() {
    if (this.closeCallback) {
      this.closeCallback();
      next(() => document.querySelector(".d-editor-input")?.focus());
    }
  }

  addListener() {
    if (!this.listenerAdded) {
      document.addEventListener("keydown", this.handleKeyDown.bind(this), true);
      this.listenerAdded = true;
    }
  }

  removeListener() {
    if (this.listenerAdded) {
      document.removeEventListener(
        "keydown",
        this.handleKeyDown.bind(this),
        true
      );
      this.listenerAdded = false;
    }
  }

  handleKeyDown(event) {
    const autocompleteMenu = document.querySelector(".autocomplete.with-fluff");
    if (!autocompleteMenu) {
      return;
    }

    const fluffSelector = this.getFluffSelector();

    if (fluffSelector) {
      const focusInFluff = this.isFocusInFluffSelector();

      if (focusInFluff) {
        const navKeys = [
          "ArrowRight",
          "ArrowLeft",
          "ArrowUp",
          "ArrowDown",
          "Enter",
          "Escape",
          "Backspace",
        ];

        if (navKeys.includes(event.key)) {
          event.preventDefault();
          event.stopPropagation();
          event.stopImmediatePropagation();

          const buttons = fluffSelector.querySelectorAll(
            ".btn-fluff-container"
          );

          switch (event.key) {
            case "ArrowRight":
              this.navigateGrid("right", buttons);
              break;
            case "ArrowLeft":
              this.navigateGrid("left", buttons);
              break;
            case "ArrowDown":
              this.navigateGrid("down", buttons);
              break;
            case "ArrowUp":
              this.navigateGrid("up", buttons);
              break;
            case "Enter":
              buttons[this.currentIndex]?.classList.remove("keyboard-focused");
              buttons[this.currentIndex]?.click();
              break;
            case "Escape":
            case "Backspace":
              this.closeFluffSelector();
              break;
          }
          return false;
        }
      }

      const blockKeys = [
        "ArrowUp",
        "ArrowDown",
        "ArrowLeft",
        "ArrowRight",
        "Enter",
      ];
      if (!focusInFluff && blockKeys.includes(event.key)) {
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();

        return false;
      }
    }

    if (event.key === "ArrowRight") {
      const selectedItem = autocompleteMenu
        .querySelector("li a.selected")
        ?.closest("li");

      if (selectedItem?.dataset.code) {
        const fluffButton = selectedItem.querySelector(".btn-fluff-selector");

        if (fluffButton) {
          event.preventDefault();
          event.stopPropagation();

          fluffButton.click();

          // Focus first button after tooltip renders
          schedule("afterRender", () => {
            const buttons = this.getFluffSelector()?.querySelectorAll(
              ".btn-fluff-container"
            );
            if (buttons?.[0]) {
              this.currentIndex = 0;
              this.gridDimensions = null;
              this.highlightButton(buttons, 0);
            }
          });
        }
      }
    }
  }
}
