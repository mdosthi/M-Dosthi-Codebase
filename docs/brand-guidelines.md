# mDosthi Brand & Design System

<p align="center">
  <img src="../apps/web/images/mdosthi-primary-logo.png" alt="mDosthi Primary Logo" width="520" />
</p>

**mDosthi — Digital Health & Well-Being · Healthcare as Homecare**  
*Care • Support • Hope*

---

## 1. Official Brand Assets

| Asset | Purpose | Web Path | Mobile / Flutter Path |
|---|---|---|---|
| **Primary Logo** | Website hero, README, official printable prescriptions & clinical reports | `apps/web/images/mdosthi-primary-logo.png` | `apps/mobile/assets/images/mdosthi-primary-logo.png` |
| **Horizontal Logo** | Clinical & patient portal headers, navigation bars | `apps/web/images/mdosthi-horizontal-logo.png` | `apps/mobile/assets/images/mdosthi-horizontal-logo.png` |
| **Standalone Emblem** | Login card medallion, dashboard badges | `apps/web/images/mdosthi-emblem.png` | `apps/mobile/assets/images/mdosthi-emblem.png` |
| **App Icon** | Mobile, desktop & PWA launcher icons (iOS, macOS, Windows, Web, Android) | `apps/web/images/icons/mdosthi-app-icon.png` | `apps/mobile/assets/icons/mDosthi.png`, `ios/`, `macos/`, `windows/`, `web/icons/` |
| **Circular Favicon / Avatar** | Browser tabs, chat & drawer avatars | `apps/web/images/icons/mdosthi-favicon.png`, `apps/web/favicon.ico`, `apps/web/images/icons/m-dosthi-favicon.svg` | `apps/mobile/web/favicon.png`, `apps/mobile/assets/icons/mdosthi-favicon.png` |
| **Feature Icons (5)** | Emotional Support, Counselling, Mental Wellness, Care Guidance, Support Community | `apps/web/images/icons/feature-*.png` | `apps/mobile/assets/icons/feature-*.png` |

---

## 2. Brand Design Tokens

Defined centrally in `apps/web/style/mdosthi-brand-tokens.css` (Web) and `apps/mobile/lib/theme/brand_theme.dart` (Flutter):

| Role | Value | CSS Token | Flutter Constant |
|---|---|---|---|
| **Navy** | `#0B2D6B` | `--color-navy` | `BrandColors.navy` |
| **Blue** | `#007BFF` | `--color-blue` | `BrandColors.blue` |
| **Teal** | `#00BFA6` | `--color-teal` | `BrandColors.teal` |
| **Green** | `#8BC34A` | `--color-green` | `BrandColors.green` |
| **Ice** | `#E0F7FA` | `--color-ice` | `BrandColors.ice` |
| **Primary CTA Gradient** | `linear-gradient(135deg, #0B2D6B 0%, #007BFF 50%, #00BFA6 100%)` | `--gradient-cta` | `BrandColors.ctaGradient` |

---

## 3. Typography

- **Headings (`--font-heading`):** `Poppins`, sans-serif
- **Body (`--font-body`):** `Inter`, sans-serif
- **Subtext (`--font-subtext`):** `Lora`, serif

---

## 4. Official Printable Documents

All printable clinical templates include the official Primary Logo letterhead (`mdosthi-primary-logo.png`, base64-embedded for PDF exports):
- `apps/web/jspfiles/previewPres.jsp` & `apps/web/jspfiles/dispres1.jsp` (prescriptions & iText PDFs via `presHtml.jsp` / `prestopdf.jsp`)
- `apps/web/jspfiles/dispres.jsp`, `apps/web/jspfiles/displaymed_print.jsp`, `apps/web/jspfiles/ai0_print.jsp`
- `apps/web/bootstrap/css/prcsPrnt.css` & `apps/web/bootstrap/css/prcsPrntpdf.css`
- `apps/mobile/lib/welbeing/patient_screening_report_page.dart` (Flutter clinical screening report)
