export default function migrate(settings) {
  const allowedDecorations = settings.get("allowed_decorations");

  if (allowedDecorations && allowedDecorations.includes("invert")) {
    settings.set(
      "allowed_decorations",
      allowedDecorations.replace("invert", "negative")
    );
  }
  return settings;
}
