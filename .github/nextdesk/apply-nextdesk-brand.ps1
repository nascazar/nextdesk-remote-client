$ErrorActionPreference = "Stop"

function Replace-Required([string]$Path, [string]$Old, [string]$New) {
    $content = Get-Content -LiteralPath $Path -Raw
    if (-not $content.Contains($Old)) { throw "Expected text not found in $Path" }
    Set-Content -LiteralPath $Path -Value $content.Replace($Old, $New) -NoNewline -Encoding utf8
}

Replace-Required "libs/hbb_common/src/config.rs" 'RwLock::new("RustDesk".to_owned())' 'RwLock::new("NextDeskRemote".to_owned())'
Replace-Required "libs/hbb_common/src/config.rs" 'pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];' 'pub const RENDEZVOUS_SERVERS: &[&str] = &["164.68.96.241"];'
Replace-Required "libs/hbb_common/src/config.rs" 'pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";' 'pub const RS_PUB_KEY: &str = "8yB4E2Ze4p2FFp2HIuDTN4pkZKqCgFcKAIcabJLpwYA=";'
Replace-Required "libs/hbb_common/src/config.rs" 'pub static ref BUILTIN_SETTINGS: RwLock<HashMap<String, String>> = Default::default();' @'
pub static ref BUILTIN_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from([
        ("incoming-only".to_owned(), "Y".to_owned()),
        ("disable-settings".to_owned(), "Y".to_owned()),
        ("hide-powered-by-me".to_owned(), "Y".to_owned()),
        ("disable-change-id".to_owned(), "Y".to_owned()),
        ("approve-mode".to_owned(), "click".to_owned()),
        ("verification-method".to_owned(), "use-temporary-password".to_owned()),
    ]));
'@
Replace-Required "Cargo.toml" 'ProductName = "RustDesk"' 'ProductName = "NextDesk Remote"'
Replace-Required "Cargo.toml" 'FileDescription = "RustDesk Remote Desktop"' 'FileDescription = "NextDesk Remote"'
Replace-Required "libs/portable/Cargo.toml" 'ProductName = "RustDesk"' 'ProductName = "NextDesk Remote"'
Replace-Required "libs/portable/Cargo.toml" 'FileDescription = "RustDesk Remote Desktop"' 'FileDescription = "NextDesk Remote"'
Replace-Required "flutter/windows/runner/Runner.rc" 'VALUE "FileDescription", "RustDesk Remote Desktop" "\0"' 'VALUE "FileDescription", "NextDesk Remote" "\0"'
Replace-Required "flutter/windows/runner/Runner.rc" 'VALUE "ProductName", "RustDesk" "\0"' 'VALUE "ProductName", "NextDesk Remote" "\0"'
Replace-Required "flutter/windows/runner/main.cpp" 'std::wstring app_name = L"RustDesk";' 'std::wstring app_name = L"NextDeskRemote";'
Copy-Item -LiteralPath ".github/nextdesk/app_icon.ico" -Destination "flutter/windows/runner/resources/app_icon.ico" -Force
Copy-Item -LiteralPath ".github/nextdesk/app_icon.ico" -Destination "flutter/assets/icon.ico" -Force
Copy-Item -LiteralPath ".github/nextdesk/app_icon.ico" -Destination "res/icon.ico" -Force
Copy-Item -LiteralPath ".github/nextdesk/app_icon.ico" -Destination "res/tray-icon.ico" -Force
Copy-Item -LiteralPath ".github/nextdesk/app_icon.png" -Destination "res/icon.png" -Force
Copy-Item -LiteralPath ".github/nextdesk/nextdesk_logo.png" -Destination "flutter/assets/logo.png" -Force
Copy-Item -LiteralPath ".github/nextdesk/nextdesk_logo.png" -Destination "flutter/assets/logo_light.png" -Force
Copy-Item -LiteralPath ".github/nextdesk/nextdesk_logo.png" -Destination "flutter/assets/logo_dark.png" -Force
Write-Host "NextDesk branding and private server configuration applied."
