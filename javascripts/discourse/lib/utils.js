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
