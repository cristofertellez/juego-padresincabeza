"""
Process raw spritesheets for 'Niño con candil' and 'Padre sin cabeza'.
Extracts 100% clean sprites without table lines, text, or background fringes,
and arranges them into standardized 12-row spritesheets at normal, proportional sizes.
"""
import os
import sys
from PIL import Image
import numpy as np

def locate_file(candidates):
    for c in candidates:
        if os.path.exists(c):
            return os.path.abspath(c)
    raise FileNotFoundError(f"None of the candidate files found: {candidates}")

def extract_kid():
    kid_path = locate_file([
        r"C:\Users\GUEST\Downloads\nichocandil.png.png",
        r"C:\Users\GUEST\Downloads\nichocandil.png",
        r"assets\nichocandil.png",
        r"C:\Users\GUEST\.gemini\antigravity\brain\62f3a88e-1f77-4362-839b-d2e821a2e44e\.user_uploaded\media_1792946635901_0f2ba9d5.jpg"
    ])
    print(f"Loading Kid from: {kid_path}")
    raw_img = Image.open(kid_path).convert("RGBA")
    arr = np.array(raw_img)

    animations = {i: [] for i in range(12)}

    def clean_kid_crop(crop):
        h, w = crop.shape[:2]
        mask = crop[:, :, 3] > 20
        # Exclude white/grey header text if any
        is_text = (crop[:, :, 0] > 220) & (crop[:, :, 1] > 220) & (crop[:, :, 2] > 220)
        mask = mask & (~is_text)
        ys, xs = np.where(mask)
        if len(ys) == 0:
            return None
        min_y, max_y = ys.min(), ys.max()
        min_x, max_x = xs.min(), xs.max()
        sprite = crop[min_y:max_y+1, min_x:max_x+1].copy()
        # Zero out transparent pixels
        sprite_mask = mask[min_y:max_y+1, min_x:max_x+1]
        sprite[~sprite_mask] = [0, 0, 0, 0]
        return Image.fromarray(sprite)

    # 1. IDLE (Y=175..350)
    # Centers of the 8 sprites (down: 2, left: 2, right: 2, up: 2)
    idle_centers = [
        (0, 216), (0, 366),   # idle_down
        (1, 511), (1, 659),   # idle_left
        (2, 813), (2, 963),   # idle_right
        (3, 1105), (3, 1239), # idle_up
    ]
    for anim_row, cx in idle_centers:
        crop = arr[175:350, cx-55:cx+55]
        s = clean_kid_crop(crop)
        if s:
            animations[anim_row].append(s)

    # 2. WALK (Y=496..628, subrow 1)
    divs_w = [141, 214, 289, 366, 442, 517, 590, 665, 740, 814, 885, 958, 1033, 1100, 1171, 1237, 1304]
    for i in range(16):
        x1 = divs_w[i] + 3
        x2 = divs_w[i+1] - 3
        crop = arr[496:628, x1:x2]
        s = clean_kid_crop(crop)
        if s:
            anim_row = 4 + (i // 4) # 4: down, 5: left, 6: right, 7: up
            animations[anim_row].append(s)

    # 3. RUN (Y=926..1056, subrow 1)
    divs_r = [141, 214, 289, 366, 442, 515, 589, 664, 740, 814, 885, 957, 1033, 1100, 1171, 1236, 1304]
    for i in range(16):
        x1 = divs_r[i] + 3
        x2 = divs_r[i+1] - 3
        crop = arr[926:1056, x1:x2]
        s = clean_kid_crop(crop)
        if s:
            anim_row = 8 + (i // 4) # 8: down, 9: left, 10: right, 11: up
            animations[anim_row].append(s)

    # Normal sizing in 64x64 cell:
    CELL_SIZE = 64
    GROUND_Y = 60
    MAX_COLS = 4

    out_sheet = Image.new("RGBA", (MAX_COLS * CELL_SIZE, 12 * CELL_SIZE), (0, 0, 0, 0))

    # Scale targets:
    # Idle & Walk height: 56 px (proportional width ~28-36 px)
    # Run height: 54 px
    ref_idle_h = max([f.size[1] for f in animations[0]] or [164])
    ref_walk_h = max([f.size[1] for f in animations[4]] or [132])
    ref_run_h = max([f.size[1] for f in animations[8]] or [125])

    for row_idx in range(12):
        frames = animations[row_idx]
        for col_idx, frame in enumerate(frames):
            fw, fh = frame.size
            if row_idx < 4:
                scale = 56.0 / ref_idle_h
            elif row_idx < 8:
                scale = 56.0 / ref_walk_h
            else:
                scale = 54.0 / ref_run_h

            nw = max(1, int(round(fw * scale)))
            nh = max(1, int(round(fh * scale)))
            scaled_frame = frame.resize((nw, nh), Image.Resampling.LANCZOS)

            cell_x = col_idx * CELL_SIZE
            cell_y = row_idx * CELL_SIZE
            pos_x = cell_x + (CELL_SIZE - nw) // 2
            pos_y = cell_y + (GROUND_Y - nh)

            out_sheet.paste(scaled_frame, (pos_x, pos_y), scaled_frame)

    os.makedirs("assets/sprites", exist_ok=True)
    kid_out_path = "assets/sprites/kid_clean.png"
    out_sheet.save(kid_out_path)
    print(f"Kid clean spritesheet saved to {kid_out_path} ({out_sheet.size[0]}x{out_sheet.size[1]})")

def extract_priest():
    priest_path = locate_file([
        r"C:\Users\GUEST\Downloads\padre.png",
        r"assets\padre.png",
        r"C:\Users\GUEST\.gemini\antigravity\brain\62f3a88e-1f77-4362-839b-d2e821a2e44e\.user_uploaded\media_1792946644213_6849dfe1.jpg"
    ])
    print(f"Loading Priest from: {priest_path}")
    raw_img = Image.open(priest_path).convert("RGB")
    arr = np.array(raw_img)

    animations = {i: [] for i in range(12)}

    def clean_priest_cell(y1, y2, x1, x2):
        # 3px inside dividers to completely eliminate table borders
        c = arr[y1+3:y2-3, x1+3:x2-3].copy()
        h, w = c.shape[:2]

        dist_cyan = np.sqrt(np.sum((c.astype(float) - np.array([0, 250, 253]))**2, axis=-1))
        is_pure_bg = dist_cyan < 28

        # Cyan fringe in dark robe (y > 65 in cell):
        is_fringe = (c[:, :, 0] < 55) & (c[:, :, 1] > 130) & (c[:, :, 2] > 130)
        is_fringe_robe = is_fringe & (np.arange(h)[:, None] > 65)

        is_trans = is_pure_bg | is_fringe_robe
        mask = ~is_trans
        ys, xs = np.where(mask)
        if len(ys) == 0:
            return None

        rgba = np.zeros((h, w, 4), dtype=np.uint8)
        rgba[mask, :3] = c[mask]
        rgba[mask, 3] = 255

        min_y, max_y = ys.min(), ys.max()
        min_x, max_x = xs.min(), xs.max()
        return Image.fromarray(rgba[min_y:max_y+1, min_x:max_x+1])

    # 1. SECTION 1 (IDLE): Y=80..338
    # DOWN (3 frames)
    for x1, x2 in [(4, 110), (114, 217), (221, 326)]:
        s = clean_priest_cell(80, 338, x1, x2)
        if s: animations[0].append(s)

    # LEFT (4 frames)
    w_l = (654 - 331) / 4.0
    for i in range(4):
        x1 = int(331 + i * w_l)
        x2 = int(331 + (i + 1) * w_l)
        s = clean_priest_cell(80, 338, x1, x2)
        if s: animations[1].append(s)

    # RIGHT (4 frames)
    w_r = (982 - 659) / 4.0
    for i in range(4):
        x1 = int(659 + i * w_r)
        x2 = int(659 + (i + 1) * w_r)
        s = clean_priest_cell(80, 338, x1, x2)
        if s: animations[2].append(s)

    # UP (3 frames)
    for x1, x2 in [(986, 1091), (1095, 1198), (1202, 1307)]:
        s = clean_priest_cell(80, 338, x1, x2)
        if s: animations[3].append(s)

    # 2. SECTION 2 (WALK): Y=445..675
    # DOWN (4 frames)
    w_d = (327 - 3) / 4.0
    for i in range(4):
        x1 = int(3 + i * w_d)
        x2 = int(3 + (i + 1) * w_d)
        s = clean_priest_cell(445, 675, x1, x2)
        if s: animations[4].append(s)

    # LEFT (4 frames)
    for i in range(4):
        x1 = int(331 + i * w_l)
        x2 = int(331 + (i + 1) * w_l)
        s = clean_priest_cell(445, 675, x1, x2)
        if s: animations[5].append(s)

    # RIGHT (4 frames)
    for i in range(4):
        x1 = int(659 + i * w_r)
        x2 = int(659 + (i + 1) * w_r)
        s = clean_priest_cell(445, 675, x1, x2)
        if s: animations[6].append(s)

    # UP (4 frames)
    w_u = (1308 - 986) / 4.0
    for i in range(4):
        x1 = int(986 + i * w_u)
        x2 = int(986 + (i + 1) * w_u)
        s = clean_priest_cell(445, 675, x1, x2)
        if s: animations[7].append(s)

    # 3. SECTION 3 (RUN): 2 subrows (subrow 1: Y=780..952, subrow 2: Y=960..1122)
    blocks = [
        (8, 3, 327),     # run_down
        (9, 331, 654),   # run_left
        (10, 659, 982),  # run_right
        (11, 986, 1308), # run_up
    ]
    for anim_row, bx1, bx2 in blocks:
        bw = (bx2 - bx1) / 4.0
        # Subrow 1
        for i in range(4):
            x1 = int(bx1 + i * bw)
            x2 = int(bx1 + (i + 1) * bw)
            s = clean_priest_cell(780, 952, x1, x2)
            if s: animations[anim_row].append(s)
        # Subrow 2
        for i in range(4):
            x1 = int(bx1 + i * bw)
            x2 = int(bx1 + (i + 1) * bw)
            s = clean_priest_cell(960, 1122, x1, x2)
            if s: animations[anim_row].append(s)

    for i in range(12):
        print(f"Priest row {i:2d} has {len(animations[i])} frames")

    # Priest normal sizing in 96x96 cell (48x48 pixel art scaled 2x):
    # Standing idle height: 88 px, width: ~35 px
    # Walk height: 85 px, width: ~34 px
    # Run height: 75 px (hunched forward), width: ~36 px
    CELL_SIZE = 96
    GROUND_Y = 92
    MAX_COLS = 8

    out_sheet = Image.new("RGBA", (MAX_COLS * CELL_SIZE, 12 * CELL_SIZE), (0, 0, 0, 0))

    ref_idle_h = max([f.size[1] for f in animations[0]] or [250])
    ref_walk_h = max([f.size[1] for f in animations[4]] or [224])
    ref_run_h = max([f.size[1] for f in animations[8]] or [166])

    for row_idx in range(12):
        frames = animations[row_idx]
        for col_idx, frame in enumerate(frames):
            fw, fh = frame.size
            if row_idx < 4:
                scale = 88.0 / ref_idle_h
            elif row_idx < 8:
                scale = 85.0 / ref_walk_h
            else:
                scale = 75.0 / ref_run_h

            nw = max(1, int(round(fw * scale)))
            nh = max(1, int(round(fh * scale)))
            scaled_frame = frame.resize((nw, nh), Image.Resampling.LANCZOS)

            cell_x = col_idx * CELL_SIZE
            cell_y = row_idx * CELL_SIZE
            pos_x = cell_x + (CELL_SIZE - nw) // 2
            pos_y = cell_y + (GROUND_Y - nh)

            out_sheet.paste(scaled_frame, (pos_x, pos_y), scaled_frame)

    priest_out_path = "assets/sprites/priest_clean.png"
    out_sheet.save(priest_out_path)
    print(f"Priest clean spritesheet saved to {priest_out_path} ({out_sheet.size[0]}x{out_sheet.size[1]})")

def generate_sprite_frames_resources():
    def create_tres(tres_path, tex_res_path, anim_config, cell_size):
        lines = []
        sub_count = sum(cfg[2] for cfg in anim_config)
        lines.append(f'[gd_resource type="SpriteFrames" load_steps={sub_count + 2} format=3]')
        lines.append('')
        lines.append(f'[ext_resource type="Texture2D" path="{tex_res_path}" id="1_tex"]')
        lines.append('')
        
        anim_frames = {}
        for anim_name, row_idx, count, speed in anim_config:
            anim_frames[anim_name] = []
            for c in range(count):
                sub_name = f"AtlasTexture_{anim_name}_{c}"
                lines.append(f'[sub_resource type="AtlasTexture" id="{sub_name}"]')
                lines.append('atlas = ExtResource("1_tex")')
                lines.append(f'region = Rect2({c * cell_size}, {row_idx * cell_size}, {cell_size}, {cell_size})')
                lines.append('')
                anim_frames[anim_name].append(sub_name)

        lines.append('[resource]')
        lines.append('animations = [')
        
        anim_blocks = []
        for anim_name, row_idx, count, speed in anim_config:
            frames_parts = [
                f'{{"duration": 1.0, "texture": SubResource("{sub_name}")}}'
                for sub_name in anim_frames[anim_name]
            ]
            frames_str = ",\n".join(frames_parts)
            block = (
                '{\n'
                f'"frames": [\n{frames_str}\n],\n'
                f'"loop": true,\n'
                f'"name": &"{anim_name}",\n'
                f'"speed": {speed:.1f}\n'
                '}'
            )
            anim_blocks.append(block)

        lines.append(",\n".join(anim_blocks))
        lines.append(']')
        
        with open(tres_path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        print(f"Generated {tres_path}")

    kid_anims = [
        ("idle_down", 0, 2, 4.0),
        ("idle_left", 1, 2, 4.0),
        ("idle_right", 2, 2, 4.0),
        ("idle_up", 3, 2, 4.0),
        ("walk_down", 4, 4, 8.0),
        ("walk_left", 5, 4, 8.0),
        ("walk_right", 6, 4, 8.0),
        ("walk_up", 7, 4, 8.0),
        ("run_down", 8, 4, 10.0),
        ("run_left", 9, 4, 10.0),
        ("run_right", 10, 4, 10.0),
        ("run_up", 11, 4, 10.0),
    ]

    priest_anims = [
        ("idle_down", 0, 3, 4.0),
        ("idle_left", 1, 4, 4.0),
        ("idle_right", 2, 4, 4.0),
        ("idle_up", 3, 3, 4.0),
        ("walk_down", 4, 4, 6.0),
        ("walk_left", 5, 4, 6.0),
        ("walk_right", 6, 4, 6.0),
        ("walk_up", 7, 4, 6.0),
        ("run_down", 8, 8, 10.0),
        ("run_left", 9, 8, 10.0),
        ("run_right", 10, 8, 10.0),
        ("run_up", 11, 8, 10.0),
    ]

    create_tres("assets/sprites/kid_frames.tres", "res://assets/sprites/kid_clean.png", kid_anims, 64)
    create_tres("assets/sprites/priest_frames.tres", "res://assets/sprites/priest_clean.png", priest_anims, 96)

if __name__ == "__main__":
    extract_kid()
    extract_priest()
    generate_sprite_frames_resources()
    print("Clean spritesheet extraction and SpriteFrames generation completed successfully!")
