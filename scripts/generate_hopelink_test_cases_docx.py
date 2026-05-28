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
BUILD_DIR = ROOT / "_generated_hopelink_test_cases_docx"
OUTPUT_DOCX = ROOT / "HopeLink_Black_Box_Test_Cases.docx"

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"


TEST_SECTIONS = [
    {
        "title": "Mobile Application Test Cases",
        "modules": [
            {
                "name": "User Authentication",
                "cases": [
                    {
                        "id": "TC-UA-01",
                        "case": "User Registration",
                        "steps": "1. Open registration screen\n2. Enter valid user details\n3. Submit registration form",
                        "expected": "User account is created and verification OTP/email flow is triggered.",
                    },
                    {
                        "id": "TC-UA-02",
                        "case": "Valid Login",
                        "steps": "1. Enter registered email and password\n2. Tap Login",
                        "expected": "User is authenticated and redirected to the main dashboard/home screen.",
                    },
                    {
                        "id": "TC-UA-03",
                        "case": "Invalid Login Credentials",
                        "steps": "1. Enter registered email with wrong password\n2. Tap Login",
                        "expected": "Login is rejected and an invalid credentials error message is shown.",
                    },
                    {
                        "id": "TC-UA-04",
                        "case": "OTP Verification",
                        "steps": "1. Enter the OTP received by the user\n2. Submit verification",
                        "expected": "OTP is verified and the user account becomes active/verified.",
                    },
                    {
                        "id": "TC-UA-05",
                        "case": "Forgot and Reset Password",
                        "steps": "1. Open forgot password flow\n2. Submit registered email or OTP flow\n3. Set a new password",
                        "expected": "Password reset completes successfully and the user can log in with the new password.",
                    },
                    {
                        "id": "TC-UA-06",
                        "case": "Session Restore on App Launch",
                        "steps": "1. Log in successfully\n2. Close and reopen the app",
                        "expected": "Valid session is restored and the user remains logged in.",
                    },
                ],
            },
            {
                "name": "Campaign Discovery and Donations",
                "cases": [
                    {
                        "id": "TC-CD-01",
                        "case": "Browse Campaign Listings",
                        "steps": "1. Open campaigns page\n2. Scroll the listing",
                        "expected": "Published campaigns are displayed with core details such as title, image, target, and progress.",
                    },
                    {
                        "id": "TC-CD-02",
                        "case": "View Campaign Details",
                        "steps": "1. Select a campaign from the list\n2. Open the detail screen",
                        "expected": "Campaign detail page shows description, organization, funding progress, and related actions.",
                    },
                    {
                        "id": "TC-CD-03",
                        "case": "Successful Campaign Donation",
                        "steps": "1. Open a valid active campaign\n2. Enter donation amount\n3. Complete payment",
                        "expected": "Donation is recorded successfully and appears in user history and campaign totals.",
                    },
                    {
                        "id": "TC-CD-04",
                        "case": "Failed Donation Payment",
                        "steps": "1. Open donation flow\n2. Enter donation amount\n3. Use failed or invalid payment path",
                        "expected": "Donation is not finalized and the user receives a payment failure message.",
                    },
                ],
            },
            {
                "name": "Saved Causes",
                "cases": [
                    {
                        "id": "TC-SC-01",
                        "case": "Save a Campaign/Event/Job",
                        "steps": "1. Open a campaign, event, or volunteer job\n2. Tap save/bookmark",
                        "expected": "Selected cause is saved to the user's saved causes list.",
                    },
                    {
                        "id": "TC-SC-02",
                        "case": "View Saved Causes",
                        "steps": "1. Open profile\n2. Navigate to saved causes",
                        "expected": "Previously saved campaigns, events, and volunteer jobs are listed correctly.",
                    },
                ],
            },
            {
                "name": "Essential Donations",
                "cases": [
                    {
                        "id": "TC-ED-01",
                        "case": "Browse Essential Requests",
                        "steps": "1. Open essential requests module\n2. Browse active requests",
                        "expected": "Active essential requests are displayed with category, urgency, and request details.",
                    },
                    {
                        "id": "TC-ED-02",
                        "case": "Commit Essential Donation",
                        "steps": "1. Open an essential request\n2. Choose commitment details\n3. Submit the commitment",
                        "expected": "Commitment is created successfully and linked to the logged-in user.",
                    },
                    {
                        "id": "TC-ED-03",
                        "case": "View My Essential Commitments",
                        "steps": "1. Open profile or commitments page\n2. View my essential commitments",
                        "expected": "User can see submitted commitment records and their current statuses.",
                    },
                ],
            },
            {
                "name": "Volunteer Jobs",
                "cases": [
                    {
                        "id": "TC-VJ-01",
                        "case": "Browse Volunteer Jobs",
                        "steps": "1. Open volunteer jobs page\n2. Scroll jobs list",
                        "expected": "Published volunteer jobs are displayed with title, organization, deadline, and credit hours.",
                    },
                    {
                        "id": "TC-VJ-02",
                        "case": "View Volunteer Job Details",
                        "steps": "1. Select a volunteer job\n2. Open job details",
                        "expected": "Job detail page shows requirements, description, organization, and apply action.",
                    },
                    {
                        "id": "TC-VJ-03",
                        "case": "Apply to Volunteer Job",
                        "steps": "1. Open a job detail page\n2. Upload resume/CV if required\n3. Enter whyHire details\n4. Submit application",
                        "expected": "Volunteer application is created with pending status.",
                    },
                ],
            },
            {
                "name": "Events",
                "cases": [
                    {
                        "id": "TC-EV-01",
                        "case": "Browse Events",
                        "steps": "1. Open events page\n2. Browse available events",
                        "expected": "Published events are displayed with title, category, date, and location.",
                    },
                    {
                        "id": "TC-EV-02",
                        "case": "Enroll in Event",
                        "steps": "1. Open a published event\n2. Tap Enroll",
                        "expected": "Volunteer enrollment is created and shown with pending status.",
                    },
                    {
                        "id": "TC-EV-03",
                        "case": "Withdraw Enrollment Before Event Starts",
                        "steps": "1. Open my event enrollments\n2. Select an eligible enrollment\n3. Withdraw before start time",
                        "expected": "Enrollment status is updated to withdrawn and the user is removed from the active volunteer list.",
                    },
                ],
            },
            {
                "name": "Volunteer Activity and Credits",
                "cases": [
                    {
                        "id": "TC-VC-01",
                        "case": "View Activity History",
                        "steps": "1. Open activity page\n2. Review listed activity records",
                        "expected": "User activity such as donations, event registration, and volunteer actions is displayed correctly.",
                    },
                    {
                        "id": "TC-VC-02",
                        "case": "View Volunteer Credits and Leaderboard",
                        "steps": "1. Open volunteer credits page\n2. Review personal totals and leaderboard",
                        "expected": "Volunteer credit hours, points, and leaderboard data are shown correctly.",
                    },
                ],
            },
            {
                "name": "Profile Management",
                "cases": [
                    {
                        "id": "TC-PM-01",
                        "case": "View Profile",
                        "steps": "1. Log in\n2. Open profile page",
                        "expected": "Profile page displays current user information, profile image, and quick actions.",
                    },
                    {
                        "id": "TC-PM-02",
                        "case": "Update Profile Details",
                        "steps": "1. Open edit profile\n2. Update profile fields\n3. Save changes",
                        "expected": "Updated profile information is saved and displayed on the profile page.",
                    },
                    {
                        "id": "TC-PM-03",
                        "case": "Upload Profile Photo or CV",
                        "steps": "1. Open profile management\n2. Select image or CV file\n3. Upload file",
                        "expected": "Selected profile asset is uploaded successfully and linked to the user profile.",
                    },
                ],
            },
            {
                "name": "Commerce and Orders",
                "cases": [
                    {
                        "id": "TC-CO-01",
                        "case": "Browse Products",
                        "steps": "1. Open product marketplace\n2. Browse product list",
                        "expected": "Active products are displayed with name, price, stock, and organization information.",
                    },
                    {
                        "id": "TC-CO-02",
                        "case": "Add Product to Cart",
                        "steps": "1. Open a product detail page\n2. Add product to cart",
                        "expected": "Selected product is added to the user's cart successfully.",
                    },
                    {
                        "id": "TC-CO-03",
                        "case": "Checkout Order",
                        "steps": "1. Open cart\n2. Review items\n3. Proceed through checkout and payment",
                        "expected": "Order is created successfully and payment status is recorded.",
                    },
                    {
                        "id": "TC-CO-04",
                        "case": "View Orders and Order Details",
                        "steps": "1. Open orders page\n2. Select an order",
                        "expected": "User can view order history and detailed information for the selected order.",
                    },
                ],
            },
            {
                "name": "Campaign Reports and AI Summary",
                "cases": [
                    {
                        "id": "TC-CR-01",
                        "case": "View Approved Campaign Report",
                        "steps": "1. Open campaign details\n2. Open approved report section",
                        "expected": "Approved campaign report is accessible to the user.",
                    },
                    {
                        "id": "TC-CR-02",
                        "case": "Generate or Retrieve AI Summary",
                        "steps": "1. Open approved report insights/summary\n2. Request summary",
                        "expected": "System returns an AI-generated or cached summary for the approved report.",
                    },
                ],
            },
        ],
    },
    {
        "title": "Organization and Admin Panel Test Cases",
        "modules": [
            {
                "name": "Organization Access",
                "cases": [
                    {
                        "id": "TC-OA-01",
                        "case": "Organization Registration",
                        "steps": "1. Open organization registration form\n2. Fill required organization details\n3. Submit form",
                        "expected": "Organization registration is submitted and marked for admin review.",
                    },
                    {
                        "id": "TC-OA-02",
                        "case": "Organization Login",
                        "steps": "1. Enter valid organization credentials\n2. Click Login",
                        "expected": "Organization user is authenticated and routed to the organization dashboard.",
                    },
                    {
                        "id": "TC-OA-03",
                        "case": "Admin Approves Organization",
                        "steps": "1. Admin opens pending organizations\n2. Select organization\n3. Approve registration",
                        "expected": "Organization status becomes approved and approval notification/credentials flow is triggered.",
                    },
                    {
                        "id": "TC-OA-04",
                        "case": "Admin Rejects Organization",
                        "steps": "1. Admin opens pending organizations\n2. Select organization\n3. Reject registration with reason",
                        "expected": "Organization status becomes rejected and rejection notification is sent.",
                    },
                ],
            },
            {
                "name": "Campaign Management",
                "cases": [
                    {
                        "id": "TC-CM-01",
                        "case": "Create Campaign",
                        "steps": "1. Login as organization user\n2. Open new campaign form\n3. Fill details\n4. Publish campaign",
                        "expected": "Campaign is created successfully and becomes visible in listings.",
                    },
                    {
                        "id": "TC-CM-02",
                        "case": "Edit Campaign",
                        "steps": "1. Open an existing campaign\n2. Click Edit\n3. Update details\n4. Save changes",
                        "expected": "Campaign changes are saved successfully.",
                    },
                    {
                        "id": "TC-CM-03",
                        "case": "Delete Campaign",
                        "steps": "1. Select campaign\n2. Click Delete\n3. Confirm deletion",
                        "expected": "Campaign is removed from the organization listing and no longer appears publicly.",
                    },
                ],
            },
            {
                "name": "Event Management",
                "cases": [
                    {
                        "id": "TC-EM-01",
                        "case": "Create Event",
                        "steps": "1. Open event management page\n2. Click create event\n3. Fill event details\n4. Publish event",
                        "expected": "Event is created successfully and becomes available in event listings.",
                    },
                    {
                        "id": "TC-EM-02",
                        "case": "Update Event",
                        "steps": "1. Open an existing event\n2. Edit fields such as date, status, or eligibility\n3. Save",
                        "expected": "Event details are updated successfully.",
                    },
                    {
                        "id": "TC-EM-03",
                        "case": "Approve or Reject Event Enrollment",
                        "steps": "1. Open event volunteers list\n2. Select pending volunteer\n3. Approve or reject",
                        "expected": "Enrollment status updates correctly and notification flow is triggered.",
                    },
                    {
                        "id": "TC-EM-04",
                        "case": "Grant Event Credit Hours",
                        "steps": "1. Open approved/attended volunteer record\n2. Grant credit hours",
                        "expected": "Volunteer credit record is created and user points are updated.",
                    },
                ],
            },
            {
                "name": "Volunteer Job Management",
                "cases": [
                    {
                        "id": "TC-JM-01",
                        "case": "Create Volunteer Job",
                        "steps": "1. Open jobs module\n2. Click create job\n3. Fill details\n4. Publish job",
                        "expected": "Volunteer job is created and appears in job listings.",
                    },
                    {
                        "id": "TC-JM-02",
                        "case": "Edit or Close Volunteer Job",
                        "steps": "1. Open an existing volunteer job\n2. Edit details or click close job\n3. Save",
                        "expected": "Job updates are saved or the job status changes to closed.",
                    },
                    {
                        "id": "TC-JM-03",
                        "case": "Approve or Reject Volunteer Application",
                        "steps": "1. Open job applications list\n2. Select applicant\n3. Approve or reject with reason",
                        "expected": "Application status is updated correctly and applicant is notified.",
                    },
                    {
                        "id": "TC-JM-04",
                        "case": "Grant Volunteer Job Credit Hours",
                        "steps": "1. Open approved volunteer application\n2. Grant credit hours",
                        "expected": "Credit hours are recorded and user volunteer totals are updated.",
                    },
                ],
            },
            {
                "name": "Essential Request Management",
                "cases": [
                    {
                        "id": "TC-ER-01",
                        "case": "Create Essential Request",
                        "steps": "1. Open essentials page\n2. Create a new request\n3. Fill category, urgency, and expiry details\n4. Save",
                        "expected": "Essential request is created successfully and becomes visible to users.",
                    },
                    {
                        "id": "TC-ER-02",
                        "case": "Update or Close Essential Request",
                        "steps": "1. Open an existing request\n2. Edit details or mark it closed/completed\n3. Save changes",
                        "expected": "Request status and details are updated successfully.",
                    },
                    {
                        "id": "TC-ER-03",
                        "case": "Review Essential Donation Commitments",
                        "steps": "1. Open request commitments\n2. View pledged or delivered commitments\n3. Update commitment status if needed",
                        "expected": "Organization can review and manage fulfillment status of user commitments.",
                    },
                ],
            },
            {
                "name": "Campaign Report Governance",
                "cases": [
                    {
                        "id": "TC-RG-01",
                        "case": "Organization Uploads Campaign Report",
                        "steps": "1. Open report submission module\n2. Choose campaign\n3. Upload PDF report\n4. Submit",
                        "expected": "Campaign report is uploaded successfully and stored with pending status.",
                    },
                    {
                        "id": "TC-RG-02",
                        "case": "Admin Approves Campaign Report",
                        "steps": "1. Admin opens pending reports\n2. Review report\n3. Approve submission",
                        "expected": "Report status becomes approved and is available for user-facing report access and AI summary generation.",
                    },
                    {
                        "id": "TC-RG-03",
                        "case": "Admin Rejects Campaign Report",
                        "steps": "1. Admin opens pending reports\n2. Review report\n3. Reject submission with reason",
                        "expected": "Report status becomes rejected and the organization is informed of the rejection.",
                    },
                ],
            },
            {
                "name": "Organization Commerce Management",
                "cases": [
                    {
                        "id": "TC-OC-01",
                        "case": "Create or Update Product",
                        "steps": "1. Open commerce module\n2. Add new product or edit existing product\n3. Save",
                        "expected": "Product record is created or updated successfully.",
                    },
                    {
                        "id": "TC-OC-02",
                        "case": "View Organization Orders",
                        "steps": "1. Open organization orders page\n2. Review order list",
                        "expected": "Organization can view orders related to its products.",
                    },
                    {
                        "id": "TC-OC-03",
                        "case": "Update Order Status",
                        "steps": "1. Open order details\n2. Change order status\n3. Save",
                        "expected": "Order status is updated successfully and reflected in order tracking.",
                    },
                ],
            },
            {
                "name": "Admin Monitoring and Governance",
                "cases": [
                    {
                        "id": "TC-AM-01",
                        "case": "Admin Login and Dashboard Routing",
                        "steps": "1. Enter valid admin credentials\n2. Click Login",
                        "expected": "Admin is authenticated and routed to the admin dashboard.",
                    },
                    {
                        "id": "TC-AM-02",
                        "case": "View Donation Summaries",
                        "steps": "1. Open admin monitoring or donation summary area\n2. Review organization-wise donation totals",
                        "expected": "Admin can view aggregated donation summary data across organizations.",
                    },
                    {
                        "id": "TC-AM-03",
                        "case": "Inspect Volunteer Credit Data",
                        "steps": "1. Open volunteer credits management page\n2. Review user credit or leaderboard information",
                        "expected": "Admin/organization can inspect volunteer credit and points data correctly.",
                    },
                ],
            },
        ],
    },
]


def paragraph_xml(text: str = "", style: str | None = None, bold: bool = False) -> str:
    parts = [f'<w:p xmlns:w="{W_NS}">']
    if style:
        parts.append(f'<w:pPr><w:pStyle w:val="{style}"/></w:pPr>')
    parts.append("<w:r>")
    if bold:
        parts.append("<w:rPr><w:b/></w:rPr>")
    if text:
        parts.append(f'<w:t xml:space="preserve">{escape(text)}</w:t>')
    else:
        parts.append("<w:t xml:space=\"preserve\"></w:t>")
    parts.append("</w:r></w:p>")
    return "".join(parts)


def multiline_cell_paragraphs(text: str) -> str:
    lines = text.split("\n")
    return "".join(paragraph_xml(line if line else " ") for line in lines)


def cell_xml(text: str, width: int | None = None, bold: bool = False) -> str:
    tc_pr = ""
    if width:
        tc_pr = (
            f"<w:tcPr><w:tcW w:w=\"{width}\" w:type=\"dxa\"/></w:tcPr>"
        )
    if "\n" in text:
        body = multiline_cell_paragraphs(text)
    else:
        body = paragraph_xml(text, bold=bold)
    return f"<w:tc>{tc_pr}{body}</w:tc>"


def row_xml(values: list[str], widths: list[int], header: bool = False) -> str:
    cells = [
        cell_xml(value, width=widths[idx], bold=header)
        for idx, value in enumerate(values)
    ]
    return "<w:tr>" + "".join(cells) + "</w:tr>"


def table_xml(rows: list[list[str]]) -> str:
    widths = [2200, 1400, 2200, 3400, 3000, 3000, 1200]
    tbl_pr = (
        "<w:tblPr>"
        "<w:tblStyle w:val=\"TableGrid\"/>"
        "<w:tblW w:w=\"0\" w:type=\"auto\"/>"
        "<w:tblBorders>"
        "<w:top w:val=\"single\" w:sz=\"12\" w:space=\"0\" w:color=\"000000\"/>"
        "<w:left w:val=\"single\" w:sz=\"12\" w:space=\"0\" w:color=\"000000\"/>"
        "<w:bottom w:val=\"single\" w:sz=\"12\" w:space=\"0\" w:color=\"000000\"/>"
        "<w:right w:val=\"single\" w:sz=\"12\" w:space=\"0\" w:color=\"000000\"/>"
        "<w:insideH w:val=\"single\" w:sz=\"10\" w:space=\"0\" w:color=\"000000\"/>"
        "<w:insideV w:val=\"single\" w:sz=\"10\" w:space=\"0\" w:color=\"000000\"/>"
        "</w:tblBorders>"
        "<w:tblLook w:val=\"04A0\" w:firstRow=\"1\" w:lastRow=\"0\" "
        "w:firstColumn=\"1\" w:lastColumn=\"0\" w:noHBand=\"0\" w:noVBand=\"1\"/>"
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


def make_document_xml() -> str:
    body: list[str] = []
    body.append(paragraph_xml("HopeLink Black Box Test Cases", "Heading1"))
    body.append(
        paragraph_xml(
            "This document contains Word-ready black-box test case tables for the essential HopeLink mobile and organization/admin panel features."
        )
    )
    body.append(
        paragraph_xml(
            "Note: Actual Result and Status are intentionally left as pending so they can be filled during real execution and evidence collection."
        )
    )

    header = [
        "Module",
        "Test ID",
        "Test Case",
        "Test Steps",
        "Expected Result",
        "Actual Result",
        "Status",
    ]

    for section in TEST_SECTIONS:
        body.append(paragraph_xml(section["title"], "Heading2"))
        for module in section["modules"]:
            body.append(paragraph_xml(module["name"], "Heading3"))
            rows = [header]
            for case in module["cases"]:
                rows.append(
                    [
                        module["name"],
                        case["id"],
                        case["case"],
                        case["steps"],
                        case["expected"],
                        "To be recorded during execution",
                        "Pending",
                    ]
                )
            body.append(table_xml(rows))
            body.append(paragraph_xml())

    section_props = (
        f'<w:sectPr xmlns:w="{W_NS}">'
        '<w:pgSz w:w="12240" w:h="15840"/>'
        '<w:pgMar w:top="1440" w:right="1000" w:bottom="1440" w:left="1000" '
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
            "<dc:title>HopeLink Black Box Test Cases</dc:title>"
        ),
        r"<dc:subject>.*?</dc:subject>": (
            "<dc:subject>Word-ready black box test case tables for HopeLink</dc:subject>"
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

    document_xml = make_document_xml()
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
