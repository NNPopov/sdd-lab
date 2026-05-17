# Validation: 0020 — Language Selection Button (Locale Selector)

## Manual Testing

### Button Display

- [ ] Unauthenticated user: language button is visible in AppBar next to the "Sign In" button
- [ ] Authenticated user: language button is visible in AppBar next to the username and logout button
- [ ] Button displays the current locale code: "EN" or "RU"

### Bottom Sheet

- [ ] Tap on the language button → bottom sheet opens
- [ ] Bottom sheet shows the "English" item
- [ ] Bottom sheet shows the "Русский" item
- [ ] A checkmark is shown next to the currently active locale
- [ ] The checkmark appears next to only one item
- [ ] Swipe down closes the bottom sheet without changing the language
- [ ] Tap outside the bottom sheet area closes it without changing the language

### Language Switching

- [ ] Select "Русский" → bottom sheet closes, interface instantly switches to Russian
- [ ] Select "English" → bottom sheet closes, interface instantly switches to English
- [ ] After switching, the language button shows the new code ("RU" or "EN")
- [ ] AppBar, tabs, form texts — everything re-renders in the new language without restarting

### Persistence

- [ ] Select "Русский", close the app, reopen → "Русский" language is preserved
- [ ] Select "English", close the app, reopen → "English" language is preserved
- [ ] On first launch (without saved locale) — the system locale is used

### Regression

- [ ] "Sign In" / "Sign Out" button in AppBar works correctly
- [ ] Tab navigation (Users, Posts, Tiers) is not broken
- [ ] Login/logout does not reset the selected language
- [ ] After switching language, navigation (push/pop) works correctly

## Tests

- [ ] `locale_cubit_test.dart`: `init()` with saved locale → emits saved locale
- [ ] `locale_cubit_test.dart`: `init()` without saved → no emission
- [ ] `locale_cubit_test.dart`: `setLocale(ru)` → emits `AppLocale.ru`, `saveLocale` is called
- [ ] `hive_locale_storage_adapter_test.dart`: save/load round-trip for en and ru
- [ ] `hive_locale_storage_adapter_test.dart`: `loadLocale()` with empty box → null
- [ ] `hive_locale_storage_adapter_test.dart`: unknown code → null
- [ ] `locale_selector_button_test.dart`: displays "EN" for `AppLocale.en`
- [ ] `locale_selector_button_test.dart`: tap → bottom sheet with "English" and "Русский"
- [ ] `locale_selector_button_test.dart`: tap "Русский" → `cubit.setLocale` is called
- [ ] `locale_selector_button_test.dart`: checkmark next to active locale
