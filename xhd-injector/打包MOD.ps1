$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dll = Join-Path $root 'build/Release/XHDEyeInjector.dll'
if (!(Test-Path -LiteralPath $dll)) { throw "Expected compiled injector missing: $dll" }
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist 'XHD-Independent-Injector-Observer'
New-Item -ItemType Directory -Force -Path $stage | Out-Null
Copy-Item -LiteralPath $dll -Destination (Join-Path $stage 'XHDEyeInjector.dll')
@'
[settings]
enable_replacement=0
neutralize_t3=0
suppress_ibl_t10_t11=0
'@ | Set-Content -LiteralPath (Join-Path $stage 'xhd_injector.ini') -Encoding ascii
@'
Diagnostic OBSERVER ONLY. Does not restore the X HD PS4 eye rendering.
The captured PC shader and runtime state will be logged to xhd_shader_observer.log.
The replacement option is disabled by default.
Build does NOT include a verified PS4 replacement.cso.
'@ | Set-Content -LiteralPath (Join-Path $stage 'README.txt') -Encoding utf8
$zip = Join-Path $dist 'XHD-Independent-Injector-Observer.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
if (!(Test-Path $zip)) { throw "ZIP package not created" }
Write-Host "Packaged observer DLL: $zip"
