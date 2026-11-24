param(
  [string]$Dir = "res://tests/unit,res://tests/integration",
  [string]$Test = "",
  [int]$TimeoutSec = 120,
  [switch]$Slow
)

# Mission 10 (T4): satu-satunya jalur menjalankan tes. Timeout keras 120 s.
$ErrorActionPreference = "Continue"
if ($Slow) { $env:GIMERSIA_SLOW = "1" }

$godot = $env:GODOT
if (-not $godot) { $godot = "D:\Programming\Gamedev\Godot_v4.7.2-stable_win64_console.exe" }
if (-not (Test-Path $godot)) {
  $alt = Join-Path (Split-Path -Parent $PSScriptRoot) "Godot_v4.7.2-stable_win64_console.exe"
  if (Test-Path $alt) { $godot = $alt }
}
if (-not (Test-Path $godot)) { Write-Host "GODOT tidak ditemukan: $godot"; exit 2 }

$repo = Split-Path -Parent $PSScriptRoot
$out = Join-Path ([System.IO.Path]::GetTempPath()) ("gimersia_gut_" + [guid]::NewGuid().ToString("N") + ".log")
$gutArgs = @("--headless", "--path", $repo, "-s", "res://addons/gut/gut_cmdln.gd", "-gexit", "-glog=1")
if ($Test) {
  $gutArgs += @("-gtest", $Test)
} else {
  foreach ($d in $Dir.Split(",")) { if ($d.Trim()) { $gutArgs += @("-gdir", $d.Trim()) } }
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$proc = Start-Process -FilePath $godot -ArgumentList $gutArgs -NoNewWindow -PassThru -RedirectStandardOutput $out -RedirectStandardError ($out + ".err")
$finished = $proc.WaitForExit($TimeoutSec * 1000)
$sw.Stop()

if (-not $finished) {
  & taskkill /T /F /PID $proc.Id 2>&1 | Out-Null
  Write-Host ("TIMEOUT after {0} s - cut off" -f $TimeoutSec)
  Remove-Item $out, ($out + ".err") -ErrorAction SilentlyContinue
  exit 124
}

Write-Host ("elapsed: {0:N1} s" -f $sw.Elapsed.TotalSeconds)
$lines = Get-Content $out -ErrorAction SilentlyContinue
if ($lines) { $lines | Select-Object -Last 30 }
$text = ($lines -join "`n") + (Get-Content ($out + ".err") -ErrorAction SilentlyContinue | Out-String)
$summary = $text -split "`n" | Select-String -Pattern "Tests |Passing Tests|Failing Tests|Risky|Pending|Asserts|Errors|All tests passed|failed|FAILED"
if ($summary) { Write-Host "--- summary ---"; $summary | ForEach-Object { $_.Line.Trim() } }
$code = if ($text -match "All tests passed") { 0 } else { 1 }
Remove-Item $out, ($out + ".err") -ErrorAction SilentlyContinue
exit $code
