import { SVG_NAMESPACE } from "discourse/lib/icon-library";
import { i18n } from "discourse-i18n";

// Original code from Discourse, simplified and adjusted to be more generic.

/**
 * Shows a success message and optionally a checkmark icon next to the button.
 * @param {Object} options
 * @param {String} options.selectorClass - The class of the button to show the feedback for.
 * @param {String} options.messageKey - The key of the message to show.
 * @param {Boolean} [options.withCheckmark=false] - Whether to show a checkmark icon next to the button.
 */
export default function actionFeedback({
  selectorClass,
  messageKey,
  withCheckmark = false,
}) {
  showAlert(selectorClass, messageKey, withCheckmark);
}

export function showAlert(selectorClass, messageKey, withCheckmark) {
  const actionBtn = document.querySelector(`${selectorClass}`);

  actionBtn?.classList.add("action-feedback-button");

  createAlert(i18n(messageKey), actionBtn);

  if (withCheckmark) {
    createCheckmark(actionBtn, selectorClass);
  }
}

function createAlert(message, actionBtn) {
  if (!actionBtn) {
    return;
  }

  removeElement(document.querySelector(".action-feedback-alert"));

  let alertDiv = document.createElement("div");
  alertDiv.className = "action-feedback-alert -success";
  alertDiv.textContent = message;

  actionBtn.appendChild(alertDiv);

  setTimeout(() => alertDiv.classList.add("slide-out"), 1000);
  setTimeout(() => removeElement(alertDiv), 2500);
}

function createCheckmark(btn, selectorClass) {
  const svgId = `svg_${selectorClass}`;
  const checkmark = makeCheckmarkSvg(selectorClass, svgId);
  btn.appendChild(checkmark.content);

  setTimeout(() => checkmark.classList.remove("is-visible"), 3000);
  setTimeout(() => removeElement(document.getElementById(svgId)), 3500);
}

function makeCheckmarkSvg(selectorClass, svgId) {
  const svgElement = document.createElement("template");
  svgElement.innerHTML = `
      <svg class="${selectorClass}-checkmark action-feedback-svg is-visible" id="${svgId}" xmlns="${SVG_NAMESPACE}" viewBox="0 0 52 52">
        <path class="checkmark__check" fill="none" d="M13 26 l10 10 20 -20"/>
      </svg>
    `;
  return svgElement;
}

function removeElement(element) {
  element?.parentNode?.removeChild(element);
}
