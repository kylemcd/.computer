---
name: photo-clipper
description: Crop or clip photos using native vision analysis and Pillow. Use when the user asks to crop or trim a photo, remove parts of an image, focus on a specific subject, improve composition, remove distractions from edges, or produce multiple cropped regions from a single image. Requires the image to exist as a file on disk — ask for the path if not provided.
---

# Photo Clipper

Crop images from disk using the model's built-in vision to determine crop coordinates, then Pillow to apply the cuts. No external API keys required.

## Workflow

1. **Read the image** using the Read tool to see it and get its dimensions.
2. **Determine crop boxes** by visually analyzing the image. Each crop is a `(left, upper, right, lower)` tuple in pixels.
3. **Install Pillow if needed** via a temporary venv (avoids touching system Python):
   ```bash
   python3 -m venv /tmp/imgenv && /tmp/imgenv/bin/pip install Pillow -q
   ```
4. **Apply crops** with a Python heredoc:
   ```bash
   /tmp/imgenv/bin/python3 - <<'EOF'
   from PIL import Image

   img = Image.open("/path/to/source.png")
   w, h = img.size
   print(f"Image size: {w}x{h}")

   crops = {
       "output-name-1": (left, upper, right, lower),
       "output-name-2": (left, upper, right, lower),
   }

   for name, box in crops.items():
       out = f"/path/to/output-{name}.png"
       img.crop(box).save(out)
       print(f"Saved: {out} ({box[2]-box[0]}x{box[3]-box[1]})")
   EOF
   ```
5. **Verify each crop** by reading the output files with the Read tool. Adjust coordinates and re-run if any crop looks off.
6. **Report** the output paths and dimensions to the user.

## Rules

- **Never overwrite the original.** Always write to a new file.
- **Always verify crops visually** by reading the output images before reporting done.
- **Output naming**: use descriptive kebab-case names, e.g. `photo-crop-header.png`, not `output1.png`.
- **Output location**: save alongside the source file unless the user specifies otherwise.
- **Safety**: do not remove more than 75% of any single dimension without confirming with the user.
- If Pillow is already installed system-wide, skip the venv step.

## Examples

**Crop to a specific region described in plain language:**
> "Crop just the top card from this screenshot"

Analyze the image, identify the pixel boundaries of the top card, produce one crop.

**Multiple crops from one image:**
> "Split this screenshot into three sections — the header, the middle card, and the bottom panel"

Analyze the image, define three `(left, upper, right, lower)` boxes, produce three output files.

**Remove empty space:**
> "Trim the whitespace from all edges"

Read the image, identify content boundaries visually, crop tight to the content.

**Focus on subject:**
> "Crop to just the person's face"

Identify the face region in the image and crop to it with a small margin.
