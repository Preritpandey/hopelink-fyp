from __future__ import annotations

import os
import re
import shutil
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parent.parent
SOURCE_MD = ROOT / "HopeLink_Sprint2_SRS.md"
TEMPLATE_DIR = ROOT / "_docx_extract"
BUILD_DIR = ROOT / "_generated_hopelink_sprint2_srs_docx"
OUTPUT_DOCX = ROOT / "HopeLink_Sprint2_SRS.docx"

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"


def run_props_xml(size_half_points: int = 24, bold: bool = False) -> str:
    parts = [
        "<w:rPr>",
        '<w:rFonts w:ascii="Times New Roman" w:eastAsia="Times New Roman" '
        'w:hAnsi="Times New Roman" w:cs="Times New Roman"/>',
        f'<w:sz w:val="{size_half_points}"/>',
        f'<w:szCs w:val="{size_half_points}"/>',
    ]
    if bold:
        parts.append("<w:b/><w:bCs/>")
    parts.append("</w:rPr>")
    return "".join(parts)


def p_xml(
    text: str = "",
    style: str | None = None,
    size_half_points: int = 24,
    bold: bool = False,
) -> str:
    parts = [f'<w:p xmlns:w="{W_NS}">']
    ppr_parts: list[str] = []
    if style:
        ppr_parts.append(f'<w:pStyle w:val="{style}"/>')
    if style is None:
        ppr_parts.append('<w:spacing w:after="120" w:line="240" w:lineRule="auto"/>')
    if ppr_parts:
        parts.append(f"<w:pPr>{''.join(ppr_parts)}</w:pPr>")
    if text:
        safe_text = escape(text).replace("\t", "    ")
        parts.append(
            f'<w:r>{run_props_xml(size_half_points=size_half_points, bold=bold)}'
            f'<w:t xml:space="preserve">{safe_text}</w:t></w:r>'
        )
    else:
        parts.append("<w:r/>")
    parts.append("</w:p>")
    return "".join(parts)


def cell_xml(text: str, is_header: bool = False) -> str:
    safe_text = escape(text.strip())
    tc_pr = (
        "<w:tcPr>"
        '<w:tcW w:w="4200" w:type="dxa"/>'
        '<w:tcBorders>'
        '<w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
        '<w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
        '<w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
        '<w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
        "</w:tcBorders>"
        + ('<w:shd w:val="clear" w:fill="D9EAF4"/>' if is_header else "")
        + "</w:tcPr>"
    )
    return (
        f'<w:tc xmlns:w="{W_NS}">'
        f"{tc_pr}"
        f'<w:p><w:pPr><w:spacing w:after="80" w:line="240" w:lineRule="auto"/></w:pPr>'
        f'<w:r>{run_props_xml(size_half_points=24, bold=is_header)}'
        f'<w:t xml:space="preserve">{safe_text}</w:t></w:r></w:p>'
        "</w:tc>"
    )


def table_xml(rows: list[list[str]]) -> str:
    tbl_parts = [
        f'<w:tbl xmlns:w="{W_NS}">',
        "<w:tblPr>",
        '<w:tblStyle w:val="TableGrid"/>',
        '<w:tblW w:w="0" w:type="auto"/>',
        '<w:tblBorders>'
        '<w:top w:val="single" w:sz="10" w:space="0" w:color="000000"/>'
        '<w:left w:val="single" w:sz="10" w:space="0" w:color="000000"/>'
        '<w:bottom w:val="single" w:sz="10" w:space="0" w:color="000000"/>'
        '<w:right w:val="single" w:sz="10" w:space="0" w:color="000000"/>'
        '<w:insideH w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
        '<w:insideV w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
        "</w:tblBorders>"
        '<w:tblCellMar><w:top w:w="80" w:type="dxa"/><w:left w:w="80" w:type="dxa"/>'
        '<w:bottom w:w="80" w:type="dxa"/><w:right w:w="80" w:type="dxa"/></w:tblCellMar>'
        "</w:tblPr>",
        "<w:tblGrid>",
    ]
    col_count = max(len(row) for row in rows) if rows else 0
    for _ in range(col_count):
        tbl_parts.append('<w:gridCol w:w="4200"/>')
    tbl_parts.append("</w:tblGrid>")

    for index, row in enumerate(rows):
        tbl_parts.append("<w:tr>")
        for cell in row:
            tbl_parts.append(cell_xml(cell, is_header=index == 0))
        tbl_parts.append("</w:tr>")

    tbl_parts.append("</w:tbl>")
    return "".join(tbl_parts)


def parse_table(lines: list[str], start: int) -> tuple[list[list[str]], int] | None:
    if start + 1 >= len(lines):
        return None
    if "|" not in lines[start] or "|" not in lines[start + 1]:
        return None

    separator = lines[start + 1].strip()
    if not re.fullmatch(r"\|?[\s:-]+(\|[\s:-]+)+\|?", separator):
        return None

    rows: list[list[str]] = []
    idx = start
    while idx < len(lines) and "|" in lines[idx].strip():
        raw = lines[idx].strip()
        if idx == start + 1:
            idx += 1
            continue
        parts = [part.strip() for part in raw.strip("|").split("|")]
        rows.append(parts)
        idx += 1
    return rows, idx


def make_document_xml(lines: list[str]) -> str:
    body: list[str] = []
    in_code = False
    i = 0

    while i < len(lines):
        line = lines[i].rstrip("\n")

        if line.strip().startswith("```"):
            in_code = not in_code
            i += 1
            continue

        if in_code:
            body.append(p_xml(line if line else " ", "NoSpacing"))
            i += 1
            continue

        table = parse_table(lines, i)
        if table:
            rows, next_i = table
            body.append(table_xml(rows))
            body.append(p_xml())
            i = next_i
            continue

        if not line.strip():
            body.append(p_xml("", "NormalWeb"))
            i += 1
            continue

        heading_match = re.match(r"^(#{1,6})\s+(.*)$", line)
        if heading_match:
            level = len(heading_match.group(1))
            heading_text = heading_match.group(2).strip()
            if level == 1:
                body.append(
                    p_xml(
                        heading_text,
                        "Heading1",
                        size_half_points=28,
                        bold=True,
                    )
                )
            else:
                body.append(
                    p_xml(
                        heading_text,
                        "Heading2",
                        size_half_points=24,
                        bold=True,
                    )
                )
            i += 1
            continue

        if line.startswith("- "):
            body.append(
                p_xml(
                    f"* {line[2:].strip()}",
                    "NormalWeb",
                    size_half_points=24,
                )
            )
            i += 1
            continue

        if re.match(r"^\d+\.\s+", line):
            body.append(p_xml(line, "NormalWeb", size_half_points=24))
            i += 1
            continue

        body.append(p_xml(line, "NormalWeb", size_half_points=24))
        i += 1

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
    created = (
        datetime.now(timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )

    replacements = {
        r"<dc:title>.*?</dc:title>": "<dc:title>HopeLink Sprint 2 SRS</dc:title>",
        r"<dc:subject>.*?</dc:subject>": (
            "<dc:subject>Formal SRS chapter section for HopeLink Sprint 2</dc:subject>"
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
        raise FileNotFoundError(f"Markdown source not found: {SOURCE_MD}")
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
