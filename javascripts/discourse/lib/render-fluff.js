import { schedule } from "@ember/runloop";
import { FLUFF_PREFIX } from "./constants";

const fluffReplacements = {
  invert: "negative",
};

export function removeFluff(element) {
  const images = element.querySelectorAll("img.emoji");
  images.forEach((img) => {
    const nextSibling = img.nextSibling;

    if (nextSibling && nextSibling.nodeType === Node.TEXT_NODE) {
      const textContent = nextSibling.nodeValue;

      const result = /^(?<decoration>[^:]+):/.exec(textContent);
      const decorationText = result?.groups?.decoration;

      if (decorationText && decorationText.startsWith(FLUFF_PREFIX)) {
        nextSibling.remove();
      }
    }
  });
}

function allowedDecorations(code) {
  return (
    settings.allowed_decorations.includes(code) || code in fluffReplacements
  );
}

export function renderFluff(element) {
  const images = element.querySelectorAll("img.emoji");

  images.forEach((img) => {
    const nextSibling = img.nextSibling;

    if (nextSibling && nextSibling.nodeType === Node.TEXT_NODE) {
      const textContent = nextSibling.nodeValue;

      const result = /^(?<decoration>[^:]+):/.exec(textContent);
      const decorationText = result?.groups?.decoration;

      if (!decorationText || !decorationText.startsWith(FLUFF_PREFIX)) {
        return;
      }

      const [mainDecoration, ...additionalDecoration] = decorationText
        .replace(FLUFF_PREFIX, "")
        .split(",")
        .map((decoration) => decoration.trim());

      const allowedAdditionalDecorations = ["flip", "flip_v"];

      const isMainDecorationAllowed = allowedDecorations(mainDecoration);
      const filteredAdditionalDecorations = [
        ...new Set(
          additionalDecoration.filter((decoration) =>
            allowedAdditionalDecorations.includes(decoration)
          )
        ),
      ];

      if (isMainDecorationAllowed) {
        const span = document.createElement("span");

        const allDecorations = [
          mainDecoration,
          ...filteredAdditionalDecorations,
        ];
        span.className = `fluff ${allDecorations
          .map((e) => `fluff--${e}`)
          .join(" ")}`;
        img.parentNode.insertBefore(span, img);
        span.appendChild(img);

        schedule("afterRender", () => {
          const hasFlip = allDecorations.some((e) => e === "flip");
          const hasFlipV = allDecorations.some((e) => e === "flip_v");

          if (hasFlip || hasFlipV) {
            const transform =
              getComputedStyle(img).getPropertyValue("transform");

            if (transform !== "none") {
              let [a, b, c, d, tx, ty] = transform
                .replace("matrix(", "")
                .replace(")", "")
                .split(",")
                .map(parseFloat);

              if (hasFlip) {
                a = -a;
                b = -b;
              }

              if (hasFlipV) {
                d = -d;
                c = -c;
              }

              if (mainDecoration === "slide") {
                tx = 0;
              }

              if (
                a !== transform[0] ||
                d !== transform[3] ||
                tx !== transform[4]
              ) {
                span.style.transform = `matrix(${a}, ${b}, ${c}, ${d}, ${tx}, ${ty})`;
              }
            }
          }
        });

        const restOfText = textContent.slice(decorationText.length + 1);
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
    const nonEmptyNodes = children.filter(
      (node) =>
        !(node.nodeType === Node.TEXT_NODE && node.nodeValue.trim() === "") &&
        !(node.nodeType === Node.ELEMENT_NODE && node.nodeName === "BR")
    );

    const isOnlyEmojis = nonEmptyNodes.every((node) => {
      if (node.nodeType === Node.ELEMENT_NODE) {
        return (
          node.matches("img.emoji") ||
          (node.matches("span.fluff") && node.querySelector("img.emoji"))
        );
      }
      return false;
    });

    const emojiCount = nonEmptyNodes.length;

    if (isOnlyEmojis && emojiCount <= 3) {
      nonEmptyNodes.forEach((node) => {
        if (node.matches("img.emoji")) {
          node.classList.add("only-emoji");
        } else if (node.matches("span.fluff")) {
          node.classList.add("only-emoji");
          node.querySelector("img.emoji")?.classList.add("only-emoji");
        }
      });
    }
  });
}
