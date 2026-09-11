# 012 — Phase 10 PDF / Excel / Print exports

Date: 2026-09-10

## User command

Implement Phase 10 only: PDF, Excel, and printing for existing Phase 9 reports. No new business calculations, settings redesign, taxes, or expenses.

## Packages added

| Package | Purpose |
| --- | --- |
| `pdf` | PDF document generation |
| `printing` | Print preview / share PDF (mobile, desktop, web) |
| `excel` | `.xlsx` workbook generation |
| `file_saver` | Cross-platform Excel save / browser download |

## Database changes

None. Exports use already-filtered report data from Phase 9 RPCs / `product_stock_balances`.

## Files created

- `lib/export/report_export_data.dart`
- `lib/export/report_export_builders.dart`
- `lib/export/pdf_export_service.dart`
- `lib/export/excel_export_service.dart`
- `lib/export/report_export_service.dart`
- `lib/widgets/reports/report_export_actions.dart`
- `test/export_test.dart`
- `documentation/commands/012_phase10_exports.md`

## Files modified

- All six report screens — Export PDF / Export Excel / Print actions
- `documentation/PROJECT.md`
- `README.md`
- `documentation/TESTING.md`
- `pubspec.yaml` (via `flutter pub add`)

## Features

- Export respects current date, company, search, status, and other filters
- PDF: business name (`AppStrings.appName` until settings exist), title, generated time, filters, summary KPIs, multi-page landscape table
- Excel: header + summary + bold column headers, approximate column widths, `.xlsx` save
- Print: `Printing.layoutPdf` preview; mobile label “Print / Share”
- No internal DB IDs in exports
- No stock/COGS/profit recalculation in the export layer

## Platform support

| Platform | PDF | Excel | Print |
| --- | --- | --- | --- |
| Android / iOS | Share sheet | File saver | Print / share preview |
| Web | Share/download | Browser download | Browser print dialog |
| macOS / Windows / Linux | Share/save | File saver | System print dialog |

## Tests

- `flutter analyze`
- `flutter test` (includes PDF/Excel byte generation)

## Remaining manual checks

- Open each report → Export PDF / Excel / Print with filters applied
- Confirm totals match on-screen KPIs
- Confirm cancelled sales stay excluded
- Large datasets: PDF multi-page table readability
- Mobile share + desktop print
