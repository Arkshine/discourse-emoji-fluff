import { FLUFF_PREFIX } from "./constants";

export function renderFluff(element) {
  const images = element.querySelectorAll("img.emoji");

  images.forEach((img) => {
    const nextSibling = img.nextSibling;

    if (nextSibling && nextSibling.nodeType === Node.TEXT_NODE) {
      const textContent = nextSibling.nodeValue;

      const result = /^(?<effect>[^:]+):/.exec(textContent);
      const effect = result?.groups?.effect;

      if (!effect || !effect.startsWith(FLUFF_PREFIX)) {
        return;
      }

      const effectWithoutPrefix = effect.replace(FLUFF_PREFIX, "");
      const restOfText = effect
        ? textContent.slice(effect.length + 1)
        : textContent;

      if (
        effectWithoutPrefix &&
        settings.allowed_effects.includes(effectWithoutPrefix)
      ) {
        const span = document.createElement("span");
        span.className = `fluff fluff--${effectWithoutPrefix}`;
        img.parentNode.insertBefore(span, img);
        span.appendChild(img);

        if (restOfText) {
          nextSibling.nodeValue = restOfText;
        } else {
          nextSibling.remove();
        }
      }
    }
  });
}

export function applyEmojiOnlyClass(element) {
  const paragraphs = element.querySelectorAll("p");

  paragraphs.forEach((paragraph) => {
    const children = Array.from(paragraph.childNodes);
    let emojiGroup = [];
    let validLine = true;

    children.forEach((node, index) => {
      if (node.nodeType === Node.ELEMENT_NODE) {
        const isWrapperEmoji =
          node.matches("span.fluff") && node.querySelector("img.emoji");
        const isDirectEmoji = node.matches("img.emoji");

        if (isWrapperEmoji || isDirectEmoji) {
          emojiGroup.push(node);
        } else if (!node.matches("br")) {
          validLine = false;
        }
      } else if (node.nodeType === Node.TEXT_NODE) {
        if (node.nodeValue.trim() !== "") {
          validLine = false;
        }
      }

      const nextNode = children[index + 1];

      if (
        emojiGroup.length >= 1 &&
        validLine &&
        (!nextNode ||
          (nextNode.nodeType === Node.ELEMENT_NODE && nextNode.matches("br")))
      ) {
        let spaceCount = 0;

        for (let i = Math.max(0, index - emojiGroup.length); i < index; i++) {
          const child = children[i];

          if (child.nodeType === Node.TEXT_NODE && child.nodeValue === " ") {
            spaceCount++;
          }
        }

        if (spaceCount >= emojiGroup.length - 1) {
          const hasWrapperEmoji = emojiGroup.some((e) =>
            e.matches("span.fluff")
          );
          const allDirectEmoji = emojiGroup.every((e) =>
            e.matches("img.emoji")
          );

          if (hasWrapperEmoji || !allDirectEmoji) {
            emojiGroup.forEach((emoji) => {
              emoji.classList.add("only-emoji");

              if (emoji.matches("span.fluff")) {
                emoji.querySelector("img.emoji")?.classList.add("only-emoji");
              }
            });
          }
        }

        emojiGroup = [];
        validLine = true;
      } else if (!validLine || (!nextNode && emojiGroup.length < 1)) {
        emojiGroup = [];
        validLine = true;
      }
    });
  });
}
