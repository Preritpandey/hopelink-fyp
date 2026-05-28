from __future__ import annotations

import os
import re
import shutil
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parent.parent
SOURCE_MD = ROOT / "HopeLink_Artefact_Design_and_Testing_Chapter.md"
TEMPLATE_DIR = ROOT / "_docx_extract"
BUILD_DIR = ROOT / "_generated_hopelink_artefact_docx"
OUTPUT_DOCX = ROOT / "HopeLink_Artefact_Design_and_Testing_Chapter.docx"


W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"


def p_xml(text: str = "", style: str | None = None) -> str:
    parts = [f'<w:p xmlns:w="{W_NS}">']
    if style:
      parts.append(f'<w:pPr><w:pStyle w:val="{style}"/></w:pPr>')
    if text:
      text = escape(text)
      text = text.replace("\t", "    ")
      parts.append(
          f'<w:r><w:t xml:space="preserve">{text}</w:t></w:r>'
      )
    else:
      parts.append("<w:r/>")
    parts.append("</w:p>")
    return "".join(parts)


def make_document_xml(lines: list[str]) -> str:
    body: list[str] = []
    in_code = False

    for raw_line in lines:
        line = raw_line.rstrip("\n")

        if line.strip().startswith("```"):
            in_code = not in_code
            continue

        if in_code:
            body.append(p_xml(line if line else " ", "NoSpacing"))
            continue

        if not line.strip():
            body.append(p_xml())
            continue

        heading_match = re.match(r"^(#{1,6})\s+(.*)$", line)
        if heading_match:
            level = min(len(heading_match.group(1)), 4)
            heading_text = heading_match.group(2).strip()
            style = f"Heading{level}"
            body.append(p_xml(heading_text, style))
            continue

        if line.startswith("- "):
            body.append(p_xml(f"• {line[2:].strip()}", "ListParagraph"))
            continue

        if re.match(r"^\d+\.\s+", line):
            body.append(p_xml(line, "ListParagraph"))
            continue

        body.append(p_xml(line))

    section_props = (
        f'<w:sectPr xmlns:w="{W_NS}">'
        '<w:pgSz w:w="12240" w:h="15840"/>'
        '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" '
        'w:header="708" w:footer="708" w:gutter="0"/>'
        "</w:sectPr>"
    )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<w:document xmlns:w="{W_NS}"><w:body>'
        + "".join(body)
        + section_props
        + "</w:body></w:document>"
    )


def update_core_properties(core_xml_path: Path) -> None:
    text = core_xml_path.read_text(encoding="utf-8")
    created = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

    replacements = {
        r"<dc:title>.*?</dc:title>": (
            "<dc:title>HopeLink Artefact Design and Testing Chapter</dc:title>"
        ),
        r"<dc:subject>.*?</dc:subject>": (
            "<dc:subject>FYP Report Chapter and UML Diagram Content</dc:subject>"
        ),
        r"<dc:creator>.*?</dc:creator>": "<dc:creator>OpenAI Codex</dc:creator>",
        r"<cp:lastModifiedBy>.*?</cp:lastModifiedBy>": (
            "<cp:lastModifiedBy>OpenAI Codex</cp:lastModifiedBy>"
        ),
        r"<dcterms:modified[^>]*>.*?</dcterms:modified>": (
            f'<dcterms:modified xsi:type="dcterms:W3CDTF">{created}</dcterms:modified>'
        ),
    }

    for pattern, replacement in replacements.items():
        text = re.sub(pattern, replacement, text, flags=re.DOTALL)

    if "<dcterms:created" in text:
        text = re.sub(
            r"<dcterms:created[^>]*>.*?</dcterms:created>",
            f'<dcterms:created xsi:type="dcterms:W3CDTF">{created}</dcterms:created>',
            text,
            flags=re.DOTALL,
        )

    core_xml_path.write_text(text, encoding="utf-8")


def build_docx() -> None:
    if not SOURCE_MD.exists():
        raise FileNotFoundError(f"Source file not found: {SOURCE_MD}")
    if not TEMPLATE_DIR.exists():
        raise FileNotFoundError(f"Template dir not found: {TEMPLATE_DIR}")

    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
    shutil.copytree(TEMPLATE_DIR, BUILD_DIR)

    lines = SOURCE_MD.read_text(encoding="utf-8").splitlines()
    document_xml = make_document_xml(lines)
    (BUILD_DIR / "word" / "document.xml").write_text(document_xml, encoding="utf-8")
    update_core_properties(BUILD_DIR / "docProps" / "core.xml")

    if OUTPUT_DOCX.exists():
        OUTPUT_DOCX.unlink()

    with zipfile.ZipFile(OUTPUT_DOCX, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(BUILD_DIR.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(BUILD_DIR).as_posix())


if __name__ == "__main__":
    os.chdir(ROOT)
    build_docx()
    print(OUTPUT_DOCX)
