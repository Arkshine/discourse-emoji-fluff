export function closestSquareGrid(elements) {
  const dimension = Math.ceil(Math.sqrt(elements));
  let rows = dimension;
  let columns = dimension;

  while (rows * columns < elements.length) {
    if (rows <= columns) {
      rows++;
    } else {
      columns++;
    }
  }

  return { rows, columns };
}
