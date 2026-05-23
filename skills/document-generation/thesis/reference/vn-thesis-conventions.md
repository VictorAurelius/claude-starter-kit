# Vietnamese-University Thesis Conventions

Opinionated baseline based on UTC (Đại học Giao thông Vận tải Hà Nội) spec PDF "Quy định trình bày đồ án tốt nghiệp". Similar conventions apply to HUST, UET, HCMUT, BKHN with minor differences.

## Format baseline (per `thesis-content-standard.md` §C1)

| Element | UTC convention | Verify in python-docx |
|---|---|---|
| Page size | A4 (210×297mm) | `section.page_width == Cm(21.0)` + `page_height == Cm(29.7)` |
| Margins | T=2.5 B=2.5 L=3.0 R=2.0 cm | `section.{top,bottom,left,right}_margin` |
| Body font | Times New Roman 13pt | `run.font.name == 'Times New Roman'` + `run.font.size.pt == 13` |
| H3 heading | TNR 14pt bold | Heading 3 style |
| H2 heading | TNR 16pt bold | Heading 2 style |
| H1 heading | TNR 18pt bold all-caps | Heading 1 style |
| Line spacing | 1.5 | `paragraph_format.line_spacing == 1.5` |
| Justify | Both edges | `paragraph_format.alignment == JUSTIFY` |
| Indent | First line 0.5cm (paragraphs) | `paragraph_format.first_line_indent == Cm(0.5)` |
| Page numbering | Roman frontmatter (i, ii, iii) + Arabic body (1, 2, 3...) | `section.different_first_page_header_footer` |
| Binding gutter | 0.5cm offset for binding edge | `section.gutter > 0` |

## Frontmatter structure (in order)

1. **Bìa chính (Cover page)** — School logo + Faculty + "KHÓA LUẬN TỐT NGHIỆP" + Title + Student + Advisor + Year
2. **Bìa phụ** — 6-field info table (Sinh viên / MSSV / Lớp / Khóa / GVHD / GVPB)
3. **LỜI CẢM ƠN** — Acknowledgments (1-2 trang, "em" pronoun)
4. **LỜI CAM ĐOAN** — Pledge of originality (optional bachelor, mandatory master+)
5. **TÓM TẮT** — Vietnamese abstract (~200 words)
6. **ABSTRACT** — English abstract (~200 words) — optional bachelor, recommended master+
7. **MỤC LỤC** — TOC auto-populated
8. **DANH MỤC BẢNG BIỂU** — List of tables
9. **DANH MỤC HÌNH** — List of figures
10. **DANH MỤC THUẬT NGỮ** — Glossary (terms with full meanings)
11. **DANH MỤC TỪ VIẾT TẮT** — Acronym list

Note: DANH MỤC THUẬT NGỮ + TỪ VIẾT TẮT can be ONE heading với 2 sub-sections (per BAO_CAO sample), OR 2 separate H1 headings. Adapt to your school's preference.

## Body structure (chapters)

VN cử nhân CNTT typical: 4-5 chapters body.

| Chapter | Common naming | Typical content |
|---|---|---|
| **CHƯƠNG 1** | TỔNG QUAN VỀ ĐỀ TÀI | Bối cảnh + motivation + literature review + objectives + scope + thesis structure |
| **CHƯƠNG 2** | CƠ SỞ LÝ THUYẾT + PHÂN TÍCH YÊU CẦU | Theoretical foundation + business requirements analysis + NFR |
| **CHƯƠNG 3** | THIẾT KẾ HỆ THỐNG | Architecture + data model + UML diagrams + security design |
| **CHƯƠNG 4** | TRIỂN KHAI VÀ KẾT QUẢ | Implementation walkthrough + KPI measurements + testing results |
| **KẾT LUẬN VÀ KIẾN NGHỊ** | (final section) | Tổng kết + Hạn chế + Hướng phát triển + Đóng góp khoa học |

**Anti-pattern:** Ghép Phân tích + Thiết kế + Kiến trúc vào 1 chương → committee bias toward unfocused scope.

## Numbering convention

- Chapter: `CHƯƠNG 1.` `CHƯƠNG 2.` (all-caps prefix)
- Section: `1.1`, `1.2`, `1.3` (no period after digit)
- Subsection: `1.1.1`, `1.1.2`
- Sub-subsection: `1.1.1.1`, `1.1.1.2` (rare — keep depth ≤4)

**Banned:** alpha-prefix `A.2.4`, `B.5` (internship-report style, NOT thesis style).

## Bibliography (IEEE format)

```
[N] Author, "Article title in quotes," Journal Name, vol. X, no. Y, pp. NN-MM, Month YYYY. [Online]. Available: https://... [Accessed: DD-MMM-YYYY].

[N] Author, Book Title in italic, X ed. City: Publisher, YYYY, pp. NN-MM.

[N] Author. "Section title in quotes." Website Name. Available: https://... (accessed DD-MMM-YYYY).
```

Cite in body: `[1]` ordinal by first appearance. Page-num for direct quotes: `[15, tr.314]`.

Required mix per rule §C3:
- Peer-reviewed papers (≥30%)
- Standards (ISO/IEEE/RFC) where applicable
- Vendor docs (acceptable but low weight)
- Department giáo trình (1-2 refs minimum cho cử nhân)
- VN laws nếu scope touches (PDPL 2023, Decree 13/53/2022, Thông tư 78/2021, Decree 147/2024)

## Page count target (per `thesis-content-standard.md` §4)

| Level | Target | Soft deduct | Hard cap |
|---|:---:|:---:|:---:|
| Cử nhân | 60-80 | 81-90 | >90 auto-FAIL |
| Kỹ sư | 80-110 | 111-120 | >120 auto-FAIL |
| Thạc sĩ | 120-180 | 181-200 | >200 auto-FAIL |
| Tiến sĩ | 150-300 | n/a (advisor approval) | n/a |

**Counter-intuitive:** longer ≠ better. Committee bias toward concise scholarly writing. Trim to within target.

## Cover page convention

```
[SCHOOL LOGO PNG embedded]

TRƯỜNG ĐẠI HỌC [SCHOOL NAME]
KHOA [FACULTY NAME]
BỘ MÔN [DEPARTMENT NAME]

---

KHÓA LUẬN TỐT NGHIỆP
ĐẠI HỌC [CỬ NHÂN / KỸ SƯ / THẠC SĨ]

[THESIS TITLE — VIETNAMESE, CAPS, BOLD, CENTERED]
[Subtitle if any, sentence case]

---

Sinh viên thực hiện: [HỌ TÊN]
MSSV:                [NUMBER]
Lớp:                 [CLASS CODE]
Khóa:                [YEAR]
Giảng viên hướng dẫn: [HỌC HÀM. HỌ TÊN]
Giảng viên phản biện: [HỌC HÀM. HỌ TÊN] (if assigned)

HÀ NỘI / TP. HCM — [YEAR]
```

## Bìa phụ convention

6-field info table, MUST DIFFER from bìa chính (info-focused vs title-focused):

```
[Table 6 rows × 2 columns]
Sinh viên:    [HỌ TÊN]
MSSV:         [NUMBER]
Lớp:          [CLASS CODE]
Khóa:         [YEAR]
GVHD:         [HỌC HÀM. HỌ TÊN]
GVPB:         [HỌC HÀM. HỌ TÊN]
```

## KẾT LUẬN structure (final chapter)

Per rule §C2 — 4 sub-sections (committee expects):

1. **Tổng kết** (Summary) — what was achieved against objectives in Ch.1
2. **Hạn chế** (Limitations) — honest acknowledgment of scope cuts + technical debts
3. **Hướng phát triển** (Future work) — concrete next steps + scope expansion
4. **Đóng góp khoa học** (Scientific contribution) — explicit 1-2 contributions methodological OR empirical novel

**Anti-pattern:** chỉ tổng kết + hướng phát triển (committee will ask "đóng góp khoa học cụ thể?").

## School-specific variations

- **UTC** — strict A4 + TNR + IEEE bibliography; abstract optional bachelor
- **HUST** — similar UTC; sometimes mandates abstract bachelor too
- **UET (VNU)** — IEEE bibliography; English abstract recommended bachelor
- **HCMUT** — IEEE bibliography; flexible chapter count (4-7)
- **BKHN** — similar HUST

**Adapt:** read your school's spec PDF + check 2-3 known-good samples from your faculty's archive BEFORE writing.
