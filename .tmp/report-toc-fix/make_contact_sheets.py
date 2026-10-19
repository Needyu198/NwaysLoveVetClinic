from pathlib import Path

from PIL import Image, ImageDraw


source = Path("/Users/apple/NwaysLoveVetClinic/.tmp/report-toc-fix/render-after")
output = source / "contact-sheets"
output.mkdir(exist_ok=True)
pages = sorted(source.glob("page-*.png"), key=lambda path: int(path.stem.split("-")[1]))

for sheet_number, start in enumerate(range(0, len(pages), 20), 1):
    batch = pages[start:start + 20]
    sheet = Image.new("RGB", (1000, 1400), "white")
    draw = ImageDraw.Draw(sheet)
    for offset, path in enumerate(batch):
        image = Image.open(path).convert("RGB")
        image.thumbnail((190, 260))
        x = (offset % 5) * 200 + 5
        y = (offset // 5) * 350 + 25
        sheet.paste(image, (x, y))
        draw.text((x, y - 18), path.stem, fill="black")
    sheet.save(output / f"contact-{sheet_number}.png")
