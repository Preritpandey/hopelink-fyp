from __future__ import annotations

import os
import re
import shutil
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parent.parent
TEMPLATE_DIR = ROOT / "_docx_extract"
BUILD_DIR = ROOT / "_generated_hopelink_feature_test_docx"
OUTPUT_DOCX = ROOT / "HopeLink_Feature_Test_Tables.docx"

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"


FEATURES = [
    {
        "title": "1. User Registration and OTP Verification",
        "box_title": "Feature Coverage",
        "box_body": (
            "Scope: user sign up, duplicate email handling, OTP verification, invalid OTP, resend OTP, "
            "and successful account activation.\n"
            "Applications: hope_link mobile application.\n"
            "Primary outcome: a user account is created in unverified state first and becomes active after OTP verification."
        ),
        "cases": [
            {
                "id": "UR-01",
                "scenario": "Register with valid user data",
                "preconditions": "User is on the sign-up page and backend is reachable.",
                "steps": "1. Enter valid full name, email, and password.\n2. Tap Sign Up.",
                "expected": "Account is created, auth token is returned, and user is redirected to OTP verification screen.",
                "priority": "High",
            },
            {
                "id": "UR-02",
                "scenario": "Register with empty mandatory fields",
                "preconditions": "User is on the sign-up page.",
                "steps": "1. Leave one or more required fields blank.\n2. Tap Sign Up.",
                "expected": "Client-side validation prevents submission and shows field-level validation messages.",
                "priority": "High",
            },
            {
                "id": "UR-03",
                "scenario": "Register with invalid email format",
                "preconditions": "User is on the sign-up page.",
                "steps": "1. Enter an invalid email format.\n2. Fill other fields correctly.\n3. Tap Sign Up.",
                "expected": "Email validation error is shown and registration request is not submitted.",
                "priority": "High",
            },
            {
                "id": "UR-04",
                "scenario": "Register with duplicate email",
                "preconditions": "The email already exists in the system.",
                "steps": "1. Enter a previously registered email.\n2. Submit the registration form.",
                "expected": "Registration is rejected and user sees an email already in use style error message.",
                "priority": "High",
            },
            {
                "id": "UR-05",
                "scenario": "Verify OTP with valid code",
                "preconditions": "User has completed registration and received OTP.",
                "steps": "1. Enter the correct OTP.\n2. Submit verification.",
                "expected": "OTP is accepted and the user account becomes verified.",
                "priority": "High",
            },
            {
                "id": "UR-06",
                "scenario": "Verify OTP with invalid code",
                "preconditions": "User is on OTP verification page.",
                "steps": "1. Enter an invalid or expired OTP.\n2. Submit verification.",
                "expected": "Verification fails and an OTP verification error message is shown.",
                "priority": "High",
            },
            {
                "id": "UR-07",
                "scenario": "Resend OTP for pending registration",
                "preconditions": "User account is still unverified.",
                "steps": "1. Tap Resend OTP.\n2. Wait for resend operation.",
                "expected": "A new OTP is issued and resend request completes successfully.",
                "priority": "Medium",
            },
        ],
    },
    {
        "title": "2. Organization Registration and Admin Approval",
        "box_title": "Feature Coverage",
        "box_body": (
            "Scope: organization multi-step registration, required file uploads, pending registration state, "
            "login state using organization status, and admin approval or rejection workflow.\n"
            "Applications: hopelink_admin organization portal and admin routing.\n"
            "Primary outcome: organization registration is submitted with pending status and only approved organizations gain access."
        ),
        "cases": [
            {
                "id": "OR-01",
                "scenario": "Submit organization registration with complete valid data",
                "preconditions": "Organization representative is on the registration wizard.",
                "steps": "1. Complete all registration steps.\n2. Upload all required documents.\n3. Submit the registration.",
                "expected": "Registration is submitted successfully and organization status is stored as pending.",
                "priority": "High",
            },
            {
                "id": "OR-02",
                "scenario": "Try to proceed with incomplete step data",
                "preconditions": "Organization representative is on any required step of the wizard.",
                "steps": "1. Leave required fields empty.\n2. Click Next.",
                "expected": "Step validation blocks navigation and required field errors are shown.",
                "priority": "High",
            },
            {
                "id": "OR-03",
                "scenario": "Submit without all mandatory documents",
                "preconditions": "All text steps are completed but one or more files are missing.",
                "steps": "1. Skip at least one required document.\n2. Attempt final submission.",
                "expected": "Submission is blocked and the system asks the user to upload all required documents.",
                "priority": "High",
            },
            {
                "id": "OR-04",
                "scenario": "Organization login with approved status",
                "preconditions": "Organization account exists and backend returns organization status as approved.",
                "steps": "1. Enter valid login credentials.\n2. Submit login.",
                "expected": "Authentication succeeds, token and organization details are stored, and organization dashboard opens.",
                "priority": "High",
            },
            {
                "id": "OR-05",
                "scenario": "Organization login while registration is still pending",
                "preconditions": "Organization account exists and backend returns organization status as pending.",
                "steps": "1. Enter valid login credentials.\n2. Submit login.",
                "expected": "Login response still carries organization status, but access is treated as pending and organization cannot proceed as approved user.",
                "priority": "High",
            },
            {
                "id": "OR-06",
                "scenario": "Admin reviews pending organization registration",
                "preconditions": "At least one organization registration is in pending state.",
                "steps": "1. Admin opens organization review queue.\n2. Open organization details and uploaded documents.",
                "expected": "Admin can review all submitted information required for decision making.",
                "priority": "Medium",
            },
            {
                "id": "OR-07",
                "scenario": "Admin approves organization registration",
                "preconditions": "Organization registration is pending review.",
                "steps": "1. Admin selects the pending organization.\n2. Approves the registration.",
                "expected": "Organization status changes from pending to approved and approved login path becomes available.",
                "priority": "High",
            },
            {
                "id": "OR-08",
                "scenario": "Admin rejects organization registration",
                "preconditions": "Organization registration is pending review.",
                "steps": "1. Admin selects the pending organization.\n2. Rejects the registration.",
                "expected": "Organization status changes from pending to rejected and approved access is not granted.",
                "priority": "High",
            },
        ],
    },
    {
        "title": "3. Commerce Feature: Product Purchase and Order Management",
        "box_title": "Feature Coverage",
        "box_body": (
            "Scope: product browsing, variant selection, cart operations, checkout, Stripe or Khalti payment flow, "
            "payment verification, user order history, and organization-side order status updates.\n"
            "Applications: hope_link mobile app and hopelink_admin organization commerce module.\n"
            "Primary outcome: paid orders are created successfully and organizations can confirm, deliver, or cancel them."
        ),
        "cases": [
            {
                "id": "CO-01",
                "scenario": "Browse product list successfully",
                "preconditions": "Commerce backend and products endpoint are available.",
                "steps": "1. Open product marketplace.\n2. Scroll and load products.",
                "expected": "Products are displayed with image, name, price, and organization details.",
                "priority": "Medium",
            },
            {
                "id": "CO-02",
                "scenario": "Select valid product variant",
                "preconditions": "Product contains multiple active variants.",
                "steps": "1. Open product details.\n2. Select an in-stock variant.",
                "expected": "Selected variant becomes active and price or stock information updates correctly.",
                "priority": "Medium",
            },
            {
                "id": "CO-03",
                "scenario": "Add in-stock product to cart",
                "preconditions": "User is on a product detail page with available stock.",
                "steps": "1. Select the product or variant.\n2. Tap Add to Cart.",
                "expected": "Product is added to cart and success message is shown.",
                "priority": "High",
            },
            {
                "id": "CO-04",
                "scenario": "Update cart quantity",
                "preconditions": "At least one item already exists in cart.",
                "steps": "1. Open cart.\n2. Increase or decrease item quantity.",
                "expected": "Cart is updated and recalculated subtotal is shown.",
                "priority": "High",
            },
            {
                "id": "CO-05",
                "scenario": "Submit checkout with valid shipping details",
                "preconditions": "Cart contains at least one item.",
                "steps": "1. Open checkout.\n2. Enter valid shipping address.\n3. Select payment gateway.\n4. Submit checkout.",
                "expected": "Checkout request is created and payment initialization starts for the selected gateway.",
                "priority": "High",
            },
            {
                "id": "CO-06",
                "scenario": "Successful order payment verification",
                "preconditions": "Checkout transaction has been created.",
                "steps": "1. Complete payment successfully in Stripe or Khalti.\n2. Return to app and wait for verification.",
                "expected": "Payment is verified, cart refreshes, orders refresh, and order confirmation screen appears.",
                "priority": "High",
            },
            {
                "id": "CO-07",
                "scenario": "Checkout blocked when cart is empty",
                "preconditions": "Cart has no items.",
                "steps": "1. Open checkout.\n2. Try to submit checkout.",
                "expected": "Checkout is blocked and user sees a cart is empty error.",
                "priority": "High",
            },
            {
                "id": "CO-08",
                "scenario": "Organization confirms a paid order",
                "preconditions": "Organization can access an order with status pending and payment status paid.",
                "steps": "1. Open organization orders.\n2. Select eligible order.\n3. Update status to confirmed.",
                "expected": "Order status is updated to confirmed and reflected in organization order tracking.",
                "priority": "High",
            },
            {
                "id": "CO-09",
                "scenario": "Organization marks confirmed order as delivered",
                "preconditions": "Order is already confirmed and payment is paid.",
                "steps": "1. Open order details.\n2. Update order status to delivered.",
                "expected": "Order status changes to delivered and updated state is visible to the organization.",
                "priority": "High",
            },
            {
                "id": "CO-10",
                "scenario": "User opens order history and details",
                "preconditions": "User has at least one order.",
                "steps": "1. Open orders page.\n2. Select one order from the list.",
                "expected": "Order list and detailed order information load successfully.",
                "priority": "Medium",
            },
        ],
    },
    {
        "title": "4. Essential Requests and Commitment Verification",
        "box_title": "Feature Coverage",
        "box_body": (
            "Scope: essential request creation, user browsing and filtering, donation commitment creation, "
            "pickup location selection, delivery marking, and organization verification or rejection of delivered commitments.\n"
            "Applications: hope_link mobile app and hopelink_admin essentials management module.\n"
            "Primary outcome: users pledge and deliver essential items while organizations track fulfillment and verify outcomes."
        ),
        "cases": [
            {
                "id": "ER-01",
                "scenario": "Create essential request with valid items and pickup locations",
                "preconditions": "Organization/admin is logged into essentials management module.",
                "steps": "1. Create a new request.\n2. Enter title, description, category, urgency, and expiry date.\n3. Add required items and pickup locations.\n4. Save request.",
                "expected": "Essential request is created successfully and becomes available in request listings.",
                "priority": "High",
            },
            {
                "id": "ER-02",
                "scenario": "Prevent essential request save with incomplete item or location draft",
                "preconditions": "Organization/admin is filling the request editor.",
                "steps": "1. Leave item row or pickup location row partially completed.\n2. Try to save the request.",
                "expected": "Save is blocked and validation tells the user to complete or clear the draft entry.",
                "priority": "High",
            },
            {
                "id": "ER-03",
                "scenario": "Browse and filter essential requests",
                "preconditions": "At least one essential request exists.",
                "steps": "1. Open Donate Essentials.\n2. Apply category or urgency filters.",
                "expected": "Filtered request list is loaded correctly for the selected category or urgency.",
                "priority": "Medium",
            },
            {
                "id": "ER-04",
                "scenario": "Open request detail and review remaining quantities",
                "preconditions": "At least one essential request exists.",
                "steps": "1. Select a request from the list.\n2. Open request details.",
                "expected": "Detailed request, pickup locations, and remaining item quantities are displayed correctly.",
                "priority": "Medium",
            },
            {
                "id": "ER-05",
                "scenario": "Submit donation commitment with valid quantities",
                "preconditions": "User is viewing a request with remaining quantities available.",
                "steps": "1. Select one or more item quantities.\n2. Select pickup location.\n3. Select delivery date.\n4. Submit commitment.",
                "expected": "Commitment is created successfully with pledged status and appears in My Commitments.",
                "priority": "High",
            },
            {
                "id": "ER-06",
                "scenario": "Block commitment when quantity exceeds remaining requirement",
                "preconditions": "User is on commitment form with request detail loaded.",
                "steps": "1. Enter a quantity greater than quantity remaining.\n2. Submit commitment.",
                "expected": "Commitment is rejected and system prevents over-pledging of the item.",
                "priority": "High",
            },
            {
                "id": "ER-07",
                "scenario": "Mark pledged commitment as delivered",
                "preconditions": "User has a commitment that can be marked delivered.",
                "steps": "1. Open My Commitments.\n2. Select a pledged commitment.\n3. Confirm mark delivered action.",
                "expected": "Commitment status changes from pledged to delivered.",
                "priority": "High",
            },
            {
                "id": "ER-08",
                "scenario": "Organization verifies delivered commitment",
                "preconditions": "Request contains a commitment in delivered state.",
                "steps": "1. Open request commitments bundle.\n2. Select delivered commitment.\n3. Update status to verified.",
                "expected": "Commitment status changes to verified and request fulfillment totals are refreshed.",
                "priority": "High",
            },
            {
                "id": "ER-09",
                "scenario": "Organization rejects delivered commitment",
                "preconditions": "Request contains a commitment in delivered state.",
                "steps": "1. Open request commitments bundle.\n2. Select delivered commitment.\n3. Update status to rejected.",
                "expected": "Commitment status changes to rejected and request fulfillment totals are recalculated accordingly.",
                "priority": "High",
            },
        ],
    },
]


def paragraph_xml(
    text: str = "",
    style: str | None = None,
    bold: bool = False,
    spacing_after: int | None = None,
) -> str:
    parts = [f'<w:p xmlns:w="{W_NS}">']
    ppr = []
    if style:
        ppr.append(f'<w:pStyle w:val="{style}"/>')
    if spacing_after is not None:
        ppr.append(f'<w:spacing w:after="{spacing_after}"/>')
    if ppr:
        parts.append(f"<w:pPr>{''.join(ppr)}</w:pPr>")
    parts.append("<w:r>")
    if bold:
        parts.append("<w:rPr><w:b/></w:rPr>")
    parts.append(f'<w:t xml:space="preserve">{escape(text) if text else " "}</w:t>')
    parts.append("</w:r></w:p>")
    return "".join(parts)


def multiline_paragraphs(text: str) -> str:
    return "".join(paragraph_xml(line if line else " ") for line in text.split("\n"))


def cell_xml(
    text: str,
    width: int,
    *,
    bold: bool = False,
    fill: str | None = None,
) -> str:
    tc_pr = [f'<w:tcW w:w="{width}" w:type="dxa"/>']
    if fill:
        tc_pr.append(f'<w:shd w:val="clear" w:color="auto" w:fill="{fill}"/>')
    body = multiline_paragraphs(text) if "\n" in text else paragraph_xml(text, bold=bold)
    return f"<w:tc><w:tcPr>{''.join(tc_pr)}</w:tcPr>{body}</w:tc>"


def row_xml(values: list[str], widths: list[int], *, header: bool = False) -> str:
    fill = "D9EAF7" if header else None
    cells = [
        cell_xml(value, widths[idx], bold=header, fill=fill)
        for idx, value in enumerate(values)
    ]
    return "<w:tr>" + "".join(cells) + "</w:tr>"


def table_xml(rows: list[list[str]]) -> str:
    widths = [1200, 2400, 2600, 3500, 3800, 1200, 2200, 1200]
    tbl_pr = (
        "<w:tblPr>"
        "<w:tblStyle w:val=\"TableGrid\"/>"
        "<w:tblW w:w=\"0\" w:type=\"auto\"/>"
        "<w:tblBorders>"
        "<w:top w:val=\"single\" w:sz=\"10\" w:space=\"0\" w:color=\"6B7280\"/>"
        "<w:left w:val=\"single\" w:sz=\"10\" w:space=\"0\" w:color=\"6B7280\"/>"
        "<w:bottom w:val=\"single\" w:sz=\"10\" w:space=\"0\" w:color=\"6B7280\"/>"
        "<w:right w:val=\"single\" w:sz=\"10\" w:space=\"0\" w:color=\"6B7280\"/>"
        "<w:insideH w:val=\"single\" w:sz=\"8\" w:space=\"0\" w:color=\"9CA3AF\"/>"
        "<w:insideV w:val=\"single\" w:sz=\"8\" w:space=\"0\" w:color=\"9CA3AF\"/>"
        "</w:tblBorders>"
        "<w:tblCellMar>"
        "<w:top w:w=\"70\" w:type=\"dxa\"/>"
        "<w:left w:w=\"70\" w:type=\"dxa\"/>"
        "<w:bottom w:w=\"70\" w:type=\"dxa\"/>"
        "<w:right w:w=\"70\" w:type=\"dxa\"/>"
        "</w:tblCellMar>"
        "</w:tblPr>"
    )
    tbl_grid = (
        "<w:tblGrid>"
        + "".join(f'<w:gridCol w:w="{w}"/>' for w in widths)
        + "</w:tblGrid>"
    )
    xml_rows = [row_xml(rows[0], widths, header=True)]
    xml_rows.extend(row_xml(row, widths) for row in rows[1:])
    return f'<w:tbl xmlns:w="{W_NS}">{tbl_pr}{tbl_grid}{"".join(xml_rows)}</w:tbl>'


def info_box_xml(title: str, body: str, fill: str = "EEF6FF") -> str:
    width = 11500
    title_para = paragraph_xml(title, bold=True)
    body_para = multiline_paragraphs(body)
    return (
        f'<w:tbl xmlns:w="{W_NS}">'
        "<w:tblPr>"
        "<w:tblStyle w:val=\"TableGrid\"/>"
        "<w:tblW w:w=\"0\" w:type=\"auto\"/>"
        "<w:tblBorders>"
        "<w:top w:val=\"single\" w:sz=\"14\" w:space=\"0\" w:color=\"4B5563\"/>"
        "<w:left w:val=\"single\" w:sz=\"14\" w:space=\"0\" w:color=\"4B5563\"/>"
        "<w:bottom w:val=\"single\" w:sz=\"14\" w:space=\"0\" w:color=\"4B5563\"/>"
        "<w:right w:val=\"single\" w:sz=\"14\" w:space=\"0\" w:color=\"4B5563\"/>"
        "</w:tblBorders>"
        "</w:tblPr>"
        f'<w:tblGrid><w:gridCol w:w="{width}"/></w:tblGrid>'
        "<w:tr>"
        "<w:tc>"
        f'<w:tcPr><w:tcW w:w="{width}" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="{fill}"/></w:tcPr>'
        f"{title_para}{body_para}"
        "</w:tc>"
        "</w:tr>"
        "</w:tbl>"
    )


def make_document_xml() -> str:
    body: list[str] = []
    body.append(paragraph_xml("HopeLink Feature Test Tables", "Heading1"))
    body.append(
        paragraph_xml(
            "This Word file contains structured black-box test tables for the requested HopeLink features: user registration, organization registration with admin approval, commerce purchase flow, and essential requests.",
            spacing_after=120,
        )
    )
    body.append(
        paragraph_xml(
            "Execution note: Actual Result and Status columns are intentionally left ready for live QA execution, screenshots, and sign-off.",
            spacing_after=180,
        )
    )

    header = [
        "Test ID",
        "Scenario",
        "Preconditions",
        "Test Steps",
        "Expected Result",
        "Priority",
        "Actual Result",
        "Status",
    ]

    for feature in FEATURES:
        body.append(paragraph_xml(feature["title"], "Heading2"))
        body.append(info_box_xml(feature["box_title"], feature["box_body"]))
        body.append(paragraph_xml(" "))
        rows = [header]
        for case in feature["cases"]:
            rows.append(
                [
                    case["id"],
                    case["scenario"],
                    case["preconditions"],
                    case["steps"],
                    case["expected"],
                    case["priority"],
                    "To be recorded during execution",
                    "Pending",
                ]
            )
        body.append(table_xml(rows))
        body.append(paragraph_xml(" "))

    section_props = (
        f'<w:sectPr xmlns:w="{W_NS}">'
        '<w:pgSz w:w="15840" w:h="12240" w:orient="landscape"/>'
        '<w:pgMar w:top="1000" w:right="720" w:bottom="1000" w:left="720" '
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
        r"<dc:title>.*?</dc:title>": (
            "<dc:title>HopeLink Feature Test Tables</dc:title>"
        ),
        r"<dc:subject>.*?</dc:subject>": (
            "<dc:subject>Feature-specific black-box test tables for HopeLink</dc:subject>"
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
    if not TEMPLATE_DIR.exists():
        raise FileNotFoundError(f"Template dir not found: {TEMPLATE_DIR}")

    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
    shutil.copytree(TEMPLATE_DIR, BUILD_DIR)

    (BUILD_DIR / "word" / "document.xml").write_text(
        make_document_xml(),
        encoding="utf-8",
    )
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
