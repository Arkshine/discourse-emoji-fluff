export function closestSquareGrid(count) {
  const dimension = Math.ceil(Math.sqrt(count));
  let rows = dimension;
  let columns = dimension;

  while (rows * columns < count) {
    if (rows <= columns) {
      rows++;
    } else {
      columns++;
    }
  }

  return { rows, columns };
}

/**
 * Same as core frontend/discourse/app/static/prosemirror/lib/plugin-utils.js
 */
export function getChangedRanges(tr) {
  const { steps, mapping } = tr;
  const changes = [];

  mapping.maps.forEach((stepMap, index) => {
    const ranges = [];

    // Try to collect ranges from the stepMap
    stepMap.forEach((from, to) => ranges.push({ from, to }));

    // If no ranges were collected (empty stepMap), fall back to step's from/to
    if (ranges.length === 0) {
      if (steps[index].from === undefined || steps[index].to === undefined) {
        return;
      }

      ranges.push(steps[index]);
    }

    ranges.forEach(({ from, to }) => {
      const change = { new: {}, old: {} };
      change.new.from = mapping.slice(index).map(from, -1);
      change.new.to = mapping.slice(index).map(to);
      change.old.from = mapping.invert().map(change.new.from, -1);
      change.old.to = mapping.invert().map(change.new.to);

      changes.push(change);
    });
  });

  return changes;
}

/**
 * Check if a character at the given index is a boundary (whitespace or punctuation)
 * Function can not be imported from frontend/discourse/app/static/prosemirror/lib/markdown-it.js
 */
export function isBoundary(str, index) {
  if (!str || index < 0 || index >= str.length) {
    return true;
  }

  const char = str[index];
  const code = str.charCodeAt(index);

  // Check for whitespace
  if (/\s/.test(char)) {
    return true;
  }

  // Check for common punctuation characters
  if (/[!"#$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~]/.test(char)) {
    return true;
  }

  // Check for Unicode whitespace and punctuation categories
  // Basic Unicode categories for punctuation
  if (
    (code >= 0x2000 && code <= 0x206f) || // General Punctuation
    (code >= 0x3000 && code <= 0x303f) // CJK Symbols and Punctuation
  ) {
    return true;
  }

  return false;
}
