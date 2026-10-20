// Managed by ~/.computer: home/zen-profile/user.js, stowed into the Zen profile
// by dotfiles_stow_zen_profile() in scripts/dotfiles.sh. Zen reapplies these
// on every launch, so changing one in about:config won't stick; edit it here.

// Load chrome/userChrome.css (also stowed in from this repo).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Website appearance: Light (0 = dark, 1 = light, 2 = automatic). Automatic
// would follow Zen's own window theme (dark), not macOS. chrome/userChrome.css
// keeps this applied in fullscreen too.
user_pref("layout.css.prefers-color-scheme.content-override", 1);
