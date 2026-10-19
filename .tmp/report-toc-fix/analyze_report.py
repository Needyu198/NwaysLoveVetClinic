import re
from pathlib import Path

from pypdf import PdfReader
from docx import Document


PDF = Path("/Users/apple/NwaysLoveVetClinic/.tmp/report-toc-fix/render-before/Nways Love Vet Clinic Management System Final Report.pdf")


pages = [(page.extract_text() or "") for page in PdfReader(PDF).pages]


def normalize(text):
    return re.sub(r"\s+", " ", text).strip().lower()

for kind, pattern, maximum in (
    ("Figure", r"(?:Fig|Figure)\s*:\s*([0-9]+)", 96),
    ("Table", r"Table\s*:\s*([0-9]+)", 42),
):
    mapping = {}
    for page_number, text in enumerate(pages, 1):
        if page_number <= 10:
            continue
        for number in re.findall(pattern, text, re.IGNORECASE):
            mapping.setdefault(int(number), page_number)
    print(kind, len(mapping), "missing", [n for n in range(1, maximum + 1) if n not in mapping])
    print(" ".join(f"{n}:{mapping.get(n, '?')}" for n in range(1, maximum + 1)))

docx = Document("/Users/apple/NwaysLoveVetClinic/deliverables/report-toc-fix/Nways Love Vet Clinic Management System Final Report.docx")
print("TOC")
for index in range(64, 144):
    raw = docx.paragraphs[index].text
    label = re.sub(r"\s+\d+\s*$", "", raw.replace("\t", " ")).strip()
    target = normalize(label)
    hits = []
    for page_number, text in enumerate(pages, 1):
        if page_number <= 9:
            continue
        if target in normalize(text):
            hits.append(page_number)
    print(index, repr(label), hits)
