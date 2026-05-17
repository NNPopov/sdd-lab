# Requirements: 0020 — Language Selection Button (Locale Selector)

## Business Requirements

1. A button with the short code of the current locale ("EN" / "RU") is added to the application AppBar.
2. The button is visible in any authorization state — before and after login.
3. Tapping the button opens a modal bottom sheet with a list of available languages.
4. Each language in the list is displayed in its native name: "English", "Русский".
5. A checkmark is displayed next to the active language.
6. When a language is selected, the bottom sheet closes and the interface immediately re-renders in the new language.
7. The selected language is saved to local storage (Hive).
8. On the next launch, the app starts with the saved locale.
9. If no saved locale exists — the system locale is used by default.
10. The user can close the bottom sheet without selecting (swipe down or tap outside the area).

## Constraints

- No new API calls.
- Supported languages: EN and RU only (already supported by slang).
- Adding new languages — out of scope.
- Language detection by geolocation — out of scope.
- RTL support — out of scope.
- The bottom sheet has no header — the list of languages speaks for itself.
