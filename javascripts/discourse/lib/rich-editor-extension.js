import { buildEmojiUrl, emojiExists, isCustomEmoji } from "pretty-text/emoji";
import { emojiOptions } from "discourse/lib/text";
import { ADDITIONAL_DECORATIONS, FLUFF_PREFIX } from "./constants";
import { getChangedRanges, isBoundary } from "./utils";

function parseFluffDecorations(decorationText) {
  if (!decorationText.startsWith(FLUFF_PREFIX)) {
    return null;
  }

  const [mainDecoration, ...additionalDecorations] = decorationText
    .replace(FLUFF_PREFIX, "")
    .split(",")
    .map((d) => d.trim())
    .filter(Boolean);

  const allowedSettings = settings.allowed_decorations.split("|");

  if (!mainDecoration || !allowedSettings.includes(mainDecoration)) {
    return null;
  }

  const filteredAdditional = [
    ...new Set(
      additionalDecorations.filter((d) => ADDITIONAL_DECORATIONS.includes(d))
    ),
  ];

  return {
    main: mainDecoration,
    additional: filteredAdditional,
  };
}

function createFluffString(main, additional = []) {
  const parts = [main, ...additional];
  return `${FLUFF_PREFIX}${parts.join(",")}`;
}

function parseFluffAttrs(altText) {
  const match = altText?.match(/^:([^:]+):(.+):$/);
  if (!match) {
    return false;
  }

  const decorations = parseFluffDecorations(match[2]);
  if (!decorations) {
    return false;
  }

  return {
    code: match[1],
    mainDecoration: decorations.main,
    additionalDecorations: decorations.additional,
  };
}

/** @type {RichEditorExtension} */
const extension = {
  name: "emoji-fluff",

  nodeSpec: {
    emoji_fluff: {
      attrs: {
        code: {},
        mainDecoration: {},
        additionalDecorations: { default: [] },
      },
      inline: true,
      group: "inline",
      atom: true,
      draggable: true,
      selectable: false,
      parseDOM: [
        {
          tag: "span.fluff",
          getAttrs: (dom) => {
            const img = dom.querySelector("img.emoji");
            return img ? parseFluffAttrs(img.getAttribute("alt")) : false;
          },
          priority: 61,
        },
      ],
      toDOM: (node) => {
        const opts = emojiOptions();
        const code = node.attrs.code.toLowerCase();
        const fluffStr = createFluffString(
          node.attrs.mainDecoration,
          node.attrs.additionalDecorations
        );
        const title = `:${code}:${fluffStr}:`;
        const src = buildEmojiUrl(code, opts);

        const allDecorations = [
          node.attrs.mainDecoration,
          ...node.attrs.additionalDecorations,
        ];
        const spanClasses = ["fluff"]
          .concat(allDecorations.map((d) => `fluff--${d}`))
          .join(" ");

        const imgClasses = isCustomEmoji(code, opts)
          ? "emoji emoji-custom"
          : "emoji";

        return [
          "span",
          { class: spanClasses },
          [
            "img",
            {
              class: imgClasses,
              alt: title,
              title,
              src,
            },
          ],
        ];
      },
    },
  },

  inputRules: [
    {
      match: /(^|\W):([^:]+):(f-[^:]+):$/,
      priority: 100, // Higher priority than core emoji rules
      handler: (state, match, start, end) => {
        const emojiCode = match[2];
        const fluffText = match[3];

        if (!emojiExists(emojiCode)) {
          return;
        }

        const decorations = parseFluffDecorations(fluffText);
        if (!decorations) {
          return;
        }

        const emojiStart = start + match[1].length;
        const fluffNode = state.schema.nodes.emoji_fluff.create({
          code: emojiCode,
          mainDecoration: decorations.main,
          additionalDecorations: decorations.additional,
        });

        const tr = state.tr.replaceWith(emojiStart, end, fluffNode);

        state.doc
          .resolve(emojiStart)
          .marks()
          .forEach((mark) => {
            tr.addMark(emojiStart, emojiStart + 1, mark);
          });

        return tr;
      },
      options: { undoable: false },
    },
  ],

  parse: {
    emoji_fluff: {
      node: "emoji_fluff",
      getAttrs: (token) => parseFluffAttrs(token.attrGet("alt")),
    },
  },

  serializeNode: {
    emoji_fluff(state, node) {
      state.flushClose();
      if (!isBoundary(state.out, state.out.length - 1)) {
        state.write(" ");
      }

      const fluffStr = createFluffString(
        node.attrs.mainDecoration,
        node.attrs.additionalDecorations
      );

      state.write(`:${node.attrs.code}:${fluffStr}:`);
    },
  },

  plugins: ({ pmState: { Plugin }, pmView: { Decoration, DecorationSet } }) => {
    // Converts emoji + fluff text patterns into emoji_fluff nodes
    function performConversion(state) {
      const replacements = [];

      state.doc.descendants((node, pos) => {
        if (node.type.name === "emoji" && node.attrs?.code) {
          const code = node.attrs.code;

          // Handles code from emoji picker
          const codeMatch = code.match(/^([^:]+)(?::([^:]+))?:(f-[^:]+)$/);
          if (codeMatch) {
            const [, baseEmoji, modifier, fluffText] = codeMatch;

            if (emojiExists(baseEmoji)) {
              const decorations = parseFluffDecorations(fluffText);
              if (decorations) {
                const emojiCode = modifier
                  ? `${baseEmoji}:${modifier}`
                  : baseEmoji;

                replacements.push({
                  from: pos,
                  to: pos + node.nodeSize,
                  node: state.schema.nodes.emoji_fluff.create({
                    code: emojiCode,
                    mainDecoration: decorations.main,
                    additionalDecorations: decorations.additional,
                  }),
                });
                return;
              }
            }
          }

          const afterPos = pos + node.nodeSize;
          if (afterPos > state.doc.content.size) {
            return;
          }

          const afterNode = state.doc.resolve(afterPos).nodeAfter;
          if (!afterNode?.isText) {
            return;
          }

          const match = afterNode.text.match(/^:?(f-[^:]+):(\s|$)/);
          if (!match) {
            return;
          }

          const decorations = parseFluffDecorations(match[1]);
          if (!decorations) {
            return;
          }

          const fluffTextEnd = afterPos + match[0].length;
          if (fluffTextEnd > state.doc.content.size) {
            return;
          }

          replacements.push({
            from: pos,
            to: fluffTextEnd,
            node: state.schema.nodes.emoji_fluff.create({
              code: node.attrs.code,
              mainDecoration: decorations.main,
              additionalDecorations: decorations.additional,
            }),
          });
        }
      });

      if (replacements.length === 0) {
        return null;
      }

      // Apply replacements in reverse order to keep positions valid
      const tr = state.tr;
      for (const replacement of replacements.reverse()) {
        if (replacement.from < 0 || replacement.to > tr.doc.content.size) {
          return null;
        }

        tr.replaceWith(replacement.from, replacement.to, replacement.node);
      }

      tr.setMeta("emoji-fluff-conversion", true);
      return tr;
    }

    // Converts emoji + fluff text after other plugins complete
    const emojiFluffConversion = new Plugin({
      view() {
        return {
          update(view, prevState) {
            if (!view.state.doc.eq(prevState.doc)) {
              // Defer to avoid conflicts with link plugin
              queueMicrotask(() => {
                if (!view.isDestroyed) {
                  const tr = performConversion(view.state);
                  if (tr) {
                    view.dispatch(tr);
                  }
                }
              });
            }
          },
        };
      },
    });

    // Plugin to sync only-emoji
    const syncOnlyEmojiClass = new Plugin({
      view() {
        return {
          update(view) {
            view.dom
              .querySelectorAll("span.fluff.only-emoji")
              .forEach((span) =>
                span.querySelector("img.emoji")?.classList.add("only-emoji")
              );

            view.dom
              .querySelectorAll("span.fluff:not(.only-emoji)")
              .forEach((span) =>
                span
                  .querySelector("img.emoji.only-emoji")
                  ?.classList.remove("only-emoji")
              );
          },
        };
      },
    });

    // Adds the only-emoji class to fluff emojis
    const insertOnlyEmojiClass = new Plugin({
      state: {
        init() {
          return DecorationSet.empty;
        },
        apply(tr, oldSet, _oldState, newState) {
          if (!tr.docChanged) {
            return oldSet.map(tr.mapping, tr.doc);
          }

          const changedRanges = getChangedRanges(tr);
          let newSet = oldSet.map(tr.mapping, tr.doc);

          changedRanges.forEach(({ new: { from, to } }) => {
            newState.doc.nodesBetween(from, to, (node, pos) => {
              if (!node.isTextblock) {
                return true;
              }

              const blockFrom = pos;
              const blockTo = pos + node.nodeSize;

              const existingDecorations = newSet.find(blockFrom, blockTo);
              newSet = newSet.remove(existingDecorations);

              const emojiNodes = [];
              let hasOnlyEmojis = true;

              node.descendants((child, childPos) => {
                if (
                  child.type.name === "emoji" ||
                  child.type.name === "emoji_fluff"
                ) {
                  emojiNodes.push({
                    from: blockFrom + 1 + childPos,
                    to: blockFrom + 1 + childPos + child.nodeSize,
                    isFluff: child.type.name === "emoji_fluff",
                  });
                  return true;
                }

                if (child.type.name === "text" && !child.text?.trim()) {
                  return true;
                }

                hasOnlyEmojis = false;
                return false;
              });

              if (
                emojiNodes.length > 0 &&
                emojiNodes.length <= 3 &&
                hasOnlyEmojis
              ) {
                newSet = newSet.add(
                  newState.doc,
                  emojiNodes.map((emoji) =>
                    Decoration.inline(emoji.from, emoji.to, {
                      class: "only-emoji",
                    })
                  )
                );
              }

              return false;
            });
          });

          return newSet;
        },
      },
      props: {
        decorations(state) {
          return this.getState(state);
        },
      },
    });

    return [syncOnlyEmojiClass, emojiFluffConversion, insertOnlyEmojiClass];
  },
};

export default extension;
