import re
from pathlib import Path

from docx import Document


DOCX = Path("/Users/apple/NwaysLoveVetClinic/deliverables/report-toc-fix/Nways Love Vet Clinic Management System Final Report.docx")


TOC_PAGES = {
    64: 3, 65: 10, 66: 10, 67: 10, 68: 11, 69: 11, 70: 12,
    71: 13, 72: 13, 73: 13, 74: 14, 75: 14, 76: 14, 77: 15,
    78: 16, 79: 16, 80: 16, 81: 16, 82: 17, 83: 17, 84: 17,
    85: 22, 86: 22, 87: 35, 88: 44, 89: 44, 90: 45, 91: 46,
    92: 47, 93: 51, 94: 65, 95: 66, 96: 68, 97: 71, 98: 72,
    99: 73, 100: 73, 101: 74, 102: 75, 103: 79, 104: 81,
    105: 83, 106: 83, 107: 84, 108: 86, 109: 87, 110: 89,
    111: 89, 112: 91, 113: 92, 114: 95, 115: 97, 116: 98,
    117: 98, 118: 100, 119: 101, 120: 102, 121: 102, 122: 103,
    123: 103, 124: 103, 125: 103, 126: 104, 127: 104, 128: 104,
    129: 104, 130: 105, 131: 105, 132: 105, 133: 106, 134: 106,
    135: 106, 136: 107, 137: 107, 138: 107, 139: 107, 140: 107,
    141: 108, 142: 108, 143: 109,
}

FIGURE_PAGES = {
    1: 18, 2: 19, 3: 20, 4: 21, 5: 22, 6: 23, 7: 23, 8: 24,
    9: 24, 10: 25, 11: 25, 12: 25, 13: 26, 14: 26, 15: 27,
    16: 27, 17: 28, 18: 28, 19: 28, 20: 29, 21: 29, 22: 30,
    23: 30, 24: 31, 25: 31, 26: 32, 27: 32, 28: 33, 29: 33,
    30: 34, 31: 34, 32: 36, 33: 37, 34: 38, 35: 39, 36: 44,
    37: 44, 38: 44, 39: 45, 40: 45, 41: 46, 42: 46, 43: 47,
    44: 47, 45: 48, 46: 48, 47: 49, 48: 65,
}

TABLE_PAGES = {
    1: 11, 2: 17, 3: 17, 4: 42, 5: 44, 6: 51, 7: 52, 8: 52,
    9: 52, 10: 52, 11: 53, 12: 53, 13: 54, 14: 54, 15: 54,
    16: 55, 17: 55, 18: 56, 19: 56, 20: 57, 21: 57, 22: 57,
    23: 58, 24: 58, 25: 59, 26: 59, 27: 59, 28: 60, 29: 60,
    30: 60, 31: 61, 32: 61, 33: 61, 34: 62, 35: 62, 36: 62,
    37: 63, 38: 63, 39: 63, 40: 64, 41: 64, 42: 66,
}


def replace_trailing_number(paragraph, number):
    for run in reversed(paragraph.runs):
        match = re.search(r"\d+\s*$", run.text)
        if match:
            run.text = run.text[:match.start()] + str(number) + run.text[match.end():]
            return
    raise ValueError(f"No trailing page number found in paragraph: {paragraph.text!r}")


document = Document(DOCX)

for paragraph_index, page_number in TOC_PAGES.items():
    replace_trailing_number(document.paragraphs[paragraph_index], page_number)

current_figure = None
for paragraph in document.paragraphs[146:275]:
    match = re.match(r"Figure\s+(\d+):", paragraph.text.strip())
    if match:
        current_figure = int(match.group(1))
    if current_figure is None or not re.search(r"\d+\s*$", paragraph.text):
        continue
    if current_figure >= 49:
        old_page = int(re.search(r"(\d+)\s*$", paragraph.text).group(1))
        page_number = old_page + 6
    else:
        page_number = FIGURE_PAGES[current_figure]
    replace_trailing_number(paragraph, page_number)
    current_figure = None

for paragraph in document.paragraphs[277:320]:
    match = re.match(r"Table\s+(\d+):", paragraph.text.strip())
    if match:
        replace_trailing_number(paragraph, TABLE_PAGES[int(match.group(1))])

document.save(DOCX)
