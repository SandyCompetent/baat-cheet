import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1376, 768

# 1. Base gradient canvas
bg = Image.new('RGB', (W, H), (247, 248, 252))

# 2. Aurora blurs
aurora = Image.new('RGBA', (W, H), (0, 0, 0, 0))
adraw = ImageDraw.Draw(aurora)
adraw.ellipse((-120, -120, 750, 750), fill=(199, 210, 254, 210))   # indigo-200
adraw.ellipse((750, -160, 1550, 620), fill=(221, 214, 254, 195))   # violet-200
adraw.ellipse((350, 280, 1150, 920), fill=(207, 250, 254, 170))   # cyan-100
aurora = aurora.filter(ImageFilter.GaussianBlur(95))

canvas = Image.alpha_composite(bg.convert('RGBA'), aurora)

# Subtle grid lines
grid = Image.new('RGBA', (W, H), (0, 0, 0, 0))
gdraw = ImageDraw.Draw(grid)
for x in range(0, W, 48):
    gdraw.line([(x, 0), (x, H)], fill=(15, 23, 42, 10), width=1)
for y in range(0, H, 48):
    gdraw.line([(0, y), (W, y)], fill=(15, 23, 42, 10), width=1)
canvas = Image.alpha_composite(canvas, grid)

# Load fonts
try:
    font_bold_title = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 36)
    font_sub = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 16)
    font_badge = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 13)
    font_card_title = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 13)
    font_card_sub = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 11)
except Exception:
    font_bold_title = ImageFont.load_default()
    font_sub = font_bold_title
    font_badge = font_bold_title
    font_card_title = font_bold_title
    font_card_sub = font_bold_title

# 3. Top branding & title bar
logo_path = '/Users/sandy/StudioProjects/project/chatbud/portfolio/assets/logo.png'
if os.path.exists(logo_path):
    logo = Image.open(logo_path).convert('RGBA').resize((46, 46), Image.Resampling.LANCZOS)
    canvas.paste(logo, (64, 48), logo)

draw = ImageDraw.Draw(canvas)
draw.text((122, 44), 'ChatBud', font=font_bold_title, fill=(15, 23, 42, 255))
draw.text((124, 86), 'The Multi-Agent Grounded AI Workspace · Desktop & Mobile Web', font=font_sub, fill=(71, 85, 105, 255))

# Version pill badge
badge_text = 'v2.0 • Grounded RAG & Exeter Academic'
bbox = draw.textbbox((0, 0), badge_text, font=font_badge)
bw = bbox[2] - bbox[0] + 24
bh = 28
bx, by = W - 64 - bw, 56
draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=14, fill=(255, 255, 255, 220), outline=(79, 70, 229, 80), width=1)
draw.ellipse([bx + 10, by + 10, bx + 18, by + 18], fill=(16, 185, 129, 255))
draw.text((bx + 26, by + 7), badge_text, font=font_badge, fill=(67, 56, 202, 255))

# 4. Desktop Browser Frame
desk_shot_path = '/Users/sandy/StudioProjects/project/chatbud/screenshots/desktop-chatbud.png'
desk_w, desk_h = 880, 530
dx, dy = 64, 150

# Desktop drop shadow
d_shadow = Image.new('RGBA', (desk_w + 80, desk_h + 80), (0, 0, 0, 0))
ds_draw = ImageDraw.Draw(d_shadow)
ds_draw.rounded_rectangle([40, 40, desk_w + 40, desk_h + 40], radius=18, fill=(30, 27, 75, 45))
d_shadow = d_shadow.filter(ImageFilter.GaussianBlur(30))
canvas.paste(d_shadow, (dx - 40, dy - 20), d_shadow)

# Desktop browser window
desk_win = Image.new('RGBA', (desk_w, desk_h), (255, 255, 255, 255))
d_win_draw = ImageDraw.Draw(desk_win)

# Browser top bar
bar_h = 36
d_win_draw.rectangle([0, 0, desk_w, bar_h], fill=(241, 245, 249, 255))
d_win_draw.line([(0, bar_h), (desk_w, bar_h)], fill=(226, 232, 240, 255), width=1)

# Traffic light dots
d_win_draw.ellipse([16, 12, 26, 22], fill=(248, 113, 113, 255))
d_win_draw.ellipse([34, 12, 44, 22], fill=(251, 191, 36, 255))
d_win_draw.ellipse([52, 12, 62, 22], fill=(52, 211, 153, 255))

# URL address bar
d_win_draw.rounded_rectangle([200, 7, 680, 29], radius=6, fill=(255, 255, 255, 255), outline=(203, 213, 225, 255), width=1)
d_win_draw.text((215, 9), 'https://chatbud-official.web.app', font=font_card_sub, fill=(100, 116, 139, 255))

# Paste desktop screenshot into content area
if os.path.exists(desk_shot_path):
    desk_img = Image.open(desk_shot_path).convert('RGBA')
    # Content area is desk_w x (desk_h - bar_h)
    content_h = desk_h - bar_h
    desk_img = desk_img.resize((desk_w, content_h), Image.Resampling.LANCZOS)
    desk_win.paste(desk_img, (0, bar_h))

# Clip browser corners with rounded mask
mask = Image.new('L', (desk_w, desk_h), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, desk_w, desk_h], radius=16, fill=255)

canvas.paste(desk_win, (dx, dy), mask)

# Draw subtle outer border around desktop window
draw = ImageDraw.Draw(canvas)
draw.rounded_rectangle([dx, dy, dx + desk_w, dy + desk_h], radius=16, outline=(15, 23, 42, 25), width=1)

# 5. Mobile Phone Frame (Overlapping bottom right)
mob_shot_path = '/Users/sandy/StudioProjects/project/chatbud/screenshots/message-chatbud.png'
phone_w, phone_h = 285, 580
px, py = W - phone_w - 60, H - phone_h - 25

# Phone glow shadow
p_shadow = Image.new('RGBA', (phone_w + 100, phone_h + 100), (0, 0, 0, 0))
ps_draw = ImageDraw.Draw(p_shadow)
ps_draw.rounded_rectangle([50, 50, phone_w + 50, phone_h + 50], radius=44, fill=(79, 70, 229, 65))
p_shadow = p_shadow.filter(ImageFilter.GaussianBlur(38))
canvas.paste(p_shadow, (px - 50, py - 35), p_shadow)

# Phone frame container
phone_canvas = Image.new('RGBA', (phone_w, phone_h), (15, 23, 42, 255))
bezel = 7
inner_w = phone_w - (bezel * 2)
inner_h = phone_h - (bezel * 2)

if os.path.exists(mob_shot_path):
    mob_img = Image.open(mob_shot_path).convert('RGBA')
    mob_img = mob_img.resize((inner_w, inner_h), Image.Resampling.LANCZOS)
    phone_canvas.paste(mob_img, (bezel, bezel))

# Notch / Dynamic Island pill
notch_w, notch_h = 80, 16
nx = (phone_w - notch_w) // 2
p_draw = ImageDraw.Draw(phone_canvas)
p_draw.rounded_rectangle([nx, bezel + 4, nx + notch_w, bezel + 4 + notch_h], radius=8, fill=(15, 23, 42, 255))

# Clip phone outer corners
p_mask = Image.new('L', (phone_w, phone_h), 0)
p_mask_draw = ImageDraw.Draw(p_mask)
p_mask_draw.rounded_rectangle([0, 0, phone_w, phone_h], radius=40, fill=255)

canvas.paste(phone_canvas, (px, py), p_mask)

# Border around phone
draw.rounded_rectangle([px, py, px + phone_w, py + phone_h], radius=40, outline=(255, 255, 255, 120), width=2)

# 6. Floating Glass Feature Cards
def draw_glass_card(cx, cy, cw, ch, icon_bg, title, subtitle):
    # Card shadow
    c_shadow = Image.new('RGBA', (cw + 40, ch + 40), (0, 0, 0, 0))
    cs_draw = ImageDraw.Draw(c_shadow)
    cs_draw.rounded_rectangle([20, 20, cw + 20, ch + 20], radius=16, fill=(15, 23, 42, 35))
    c_shadow = c_shadow.filter(ImageFilter.GaussianBlur(16))
    canvas.paste(c_shadow, (cx - 20, cy - 10), c_shadow)

    card = Image.new('RGBA', (cw, ch), (255, 255, 255, 235))
    cdraw = ImageDraw.Draw(card)
    cdraw.rounded_rectangle([0, 0, cw, ch], radius=16, fill=(255, 255, 255, 240), outline=(79, 70, 229, 60), width=1)
    
    # Icon square
    cdraw.rounded_rectangle([14, 12, 46, 44], radius=10, fill=icon_bg)
    cdraw.text((56, 13), title, font=font_card_title, fill=(15, 23, 42, 255))
    cdraw.text((56, 31), subtitle, font=font_card_sub, fill=(79, 70, 229, 255))

    c_mask = Image.new('L', (cw, ch), 0)
    cm_draw = ImageDraw.Draw(c_mask)
    cm_draw.rounded_rectangle([0, 0, cw, ch], radius=16, fill=255)
    canvas.paste(card, (cx, cy), c_mask)

# Card 1: Grounded RAG Engine
draw_glass_card(730, 115, 250, 56, (16, 185, 129, 230), 'Grounded RAG Engine', 'Frankfurter FX · Open-Meteo')

# Card 2: Exeter Academic
draw_glass_card(750, 580, 240, 56, (14, 165, 233, 230), 'Exeter Academic Agent', 'Campus Live · Forum 24/7')

# Card 3: Two-Layer Memory
draw_glass_card(80, 690, 240, 56, (139, 92, 246, 230), 'Two-Layer Vector Memory', 'Cosine similarity on-device')

# Save outputs
final_rgb = canvas.convert('RGB')
output_portfolio = '/Users/sandy/StudioProjects/project/chatbud/portfolio/portfolio.png'
output_screenshot = '/Users/sandy/StudioProjects/project/chatbud/screenshots/portfolio.png'

final_rgb.save(output_portfolio, quality=95)
final_rgb.save(output_screenshot, quality=95)
print('Showcase banner generated successfully:', output_portfolio)
