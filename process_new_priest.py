"""
Process new clean 4x4 spritesheet for the Headless Priest (Padre sin Cabeza).
Removes pure green (#00FF00) background and green spill/fringe,
aligns all 16 frames on a uniform 64x64 grid with locked feet baseline (no shaking),
and updates priest_clean.png and priest_frames.tres.
"""
import os
import sys
from PIL import Image
import numpy as np

def locate_priest_file():
    candidates = [
        r"C:\Users\GUEST\Downloads\padre-sin-sin.png",
        r"C:\Users\GUEST\Downloads\image_7.png",
        r"assets\image_7.png",
        r"C:\Users\GUEST\.gemini\antigravity\brain\62f3a88e-1f77-4362-839b-d2e821a2e44e\.user_uploaded\media_1792949585645_76a38f26.jpg"
    ]
    for c in candidates:
        if os.path.exists(c):
            return os.path.abspath(c)
    raise FileNotFoundError(f"None of candidate files found: {candidates}")

def process_priest():
    src_path = locate_priest_file()
    print(f"Loading Priest source from: {src_path}")
    raw_img = Image.open(src_path).convert("RGB")
    arr = np.array(raw_img).astype(float)
    img_h, img_w = arr.shape[:2]

    # Clean chroma key (green #00FF00) and de-spill
    r_ch, g_ch, b_ch = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    max_rb = np.maximum(r_ch, b_ch)
    green_excess = np.maximum(0.0, g_ch - max_rb)
    denom = np.maximum(1.0, 255.0 - max_rb)
    spill_ratio = green_excess / denom

    # Clean alpha curve
    alpha = np.clip(1.0 - (spill_ratio - 0.06) / (0.35 - 0.06), 0.0, 1.0)
    g_clean = np.where(green_excess > 0, max_rb, g_ch)

    rgba = np.zeros((img_h, img_w, 4), dtype=np.uint8)
    rgba[:, :, 0] = np.clip(r_ch, 0, 255).astype(np.uint8)
    rgba[:, :, 1] = np.clip(g_clean, 0, 255).astype(np.uint8)
    rgba[:, :, 2] = np.clip(b_ch, 0, 255).astype(np.uint8)
    rgba[:, :, 3] = (alpha * 255).astype(np.uint8)

    # 4x4 grid division
    cell_raw_w = img_w // 4
    cell_raw_h = img_h // 4

    cell_crops = []
    max_char_h = 0

    for r in range(4):
        for c in range(4):
            cell = rgba[r*cell_raw_h:(r+1)*cell_raw_h, c*cell_raw_w:(c+1)*cell_raw_w].copy()
            fg_mask = cell[:, :, 3] > 20
            ys, xs = np.where(fg_mask)
            if len(ys) == 0:
                print(f"Warning: Cell r={r}, c={c} is empty!")
                continue
            min_y, max_y = ys.min(), ys.max()
            min_x, max_x = xs.min(), xs.max()
            h = max_y - min_y + 1
            if h > max_char_h:
                max_char_h = h
            cell_crops.append(cell[min_y:max_y+1, min_x:max_x+1])

    print(f"Extracted {len(cell_crops)} priest frames. Max raw height: {max_char_h}")

    # Output Grid: 4 cols x 4 rows in 64x64 cells = 256x256 px
    CELL_SIZE = 64
    GROUND_Y = 60 # Bottom foot baseline locked across all frames
    TARGET_HEIGHT = 58.0
    scale = TARGET_HEIGHT / float(max_char_h)

    out_sheet = Image.new("RGBA", (4 * CELL_SIZE, 4 * CELL_SIZE), (0, 0, 0, 0))

    for idx, crop in enumerate(cell_crops):
        r = idx // 4
        c = idx % 4
        crop_im = Image.fromarray(crop)
        cw, ch = crop_im.size
        nw = max(1, int(round(cw * scale)))
        nh = max(1, int(round(ch * scale)))
        resized = crop_im.resize((nw, nh), Image.Resampling.LANCZOS)

        pos_x = (CELL_SIZE - nw) // 2 # Horizontally centered
        pos_y = GROUND_Y - nh         # Grounded at exact same baseline Y=60

        out_sheet.paste(resized, (c * CELL_SIZE + pos_x, r * CELL_SIZE + pos_y), resized)

    os.makedirs("assets/sprites", exist_ok=True)
    out_png_path = "assets/sprites/priest_clean.png"
    out_sheet.save(out_png_path)
    print(f"Saved priest clean spritesheet to {out_png_path} ({out_sheet.size[0]}x{out_sheet.size[1]})")

def generate_priest_frames_tres():
    # 16 frames in 4x4 grid (64x64 each)
    # Row 0: 0, 1, 2, 3 (Down)
    # Row 1: 4, 5, 6, 7 (Left)
    # Row 2: 8, 9, 10, 11 (Right)
    # Row 3: 12, 13, 14, 15 (Up)
    anim_definitions = [
        # (anim_name, frames_indices, speed)
        ("idle_down", [0], 5.0),
        ("walk_down", [0, 1, 2, 3], 7.0),
        ("run_down", [0, 1, 2, 3], 12.0),
        ("idle_left", [4], 5.0),
        ("walk_left", [4, 5, 6, 7], 7.0),
        ("run_left", [4, 5, 6, 7], 12.0),
        ("idle_right", [8], 5.0),
        ("walk_right", [8, 9, 10, 11], 7.0),
        ("run_right", [8, 9, 10, 11], 12.0),
        ("idle_up", [12], 5.0),
        ("walk_up", [12, 13, 14, 15], 7.0),
        ("run_up", [12, 13, 14, 15], 12.0),
    ]

    lines = []
    lines.append('[gd_resource type="SpriteFrames" load_steps=18 format=3]')
    lines.append('')
    lines.append('[ext_resource type="Texture2D" path="res://assets/sprites/priest_clean.png" id="1_tex"]')
    lines.append('')

    # Create 16 AtlasTextures (one for each cell)
    for i in range(16):
        r = i // 4
        c = i % 4
        lines.append(f'[sub_resource type="AtlasTexture" id="AtlasTexture_{i}"]')
        lines.append('atlas = ExtResource("1_tex")')
        lines.append(f'region = Rect2({c * 64}, {r * 64}, 64, 64)')
        lines.append('')

    lines.append('[resource]')
    lines.append('animations = [')

    anim_blocks = []
    for name, f_indices, speed in anim_definitions:
        frames_parts = [
            f'{{"duration": 1.0, "texture": SubResource("AtlasTexture_{idx}")}}'
            for idx in f_indices
        ]
        frames_str = ",\n".join(frames_parts)
        block = (
            '{\n'
            f'"frames": [\n{frames_str}\n],\n'
            f'"loop": true,\n'
            f'"name": &"{name}",\n'
            f'"speed": {speed:.1f}\n'
            '}'
        )
        anim_blocks.append(block)

    lines.append(",\n".join(anim_blocks))
    lines.append(']')

    tres_path = "assets/sprites/priest_frames.tres"
    with open(tres_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated {tres_path} with 12 animations.")

if __name__ == "__main__":
    process_priest()
    generate_priest_frames_tres()
    print("Headless Priest processing completed successfully!")
