# =============================================================================
# Roda o app Flutter LOCAL apontado para o STAGING.
# Injeta as chaves via --dart-define (tem prioridade sobre o .env), então
# NÃO toca na config de produção. Uso:  ./run-staging.ps1
# =============================================================================
$ErrorActionPreference = "Stop"

$envFile = Join-Path $PSScriptRoot ".env.staging"
if (-not (Test-Path $envFile)) {
    Write-Error ".env.staging nao encontrado. Crie-o com SUPABASE_URL e SUPABASE_ANON_KEY do staging."
    exit 1
}

# Le o .env.staging (formato KEY=VALUE, ignora comentarios)
$vars = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $idx = $line.IndexOf("=")
        $vars[$line.Substring(0, $idx).Trim()] = $line.Substring($idx + 1).Trim()
    }
}

if (-not $vars["SUPABASE_ANON_KEY"] -or $vars["SUPABASE_ANON_KEY"] -eq "COLE_A_ANON_KEY_DO_STAGING_AQUI") {
    Write-Error "Preencha SUPABASE_ANON_KEY no .env.staging (Settings -> API Keys -> anon public do staging)."
    exit 1
}

$defines = @()
foreach ($k in @("SUPABASE_URL", "SUPABASE_ANON_KEY", "MASTER_DATA_CSV_URL")) {
    if ($vars.ContainsKey($k) -and $vars[$k]) { $defines += "--dart-define=$k=$($vars[$k])" }
}

# Sinaliza ambiente de testes -> liga o banner "AMBIENTE DE TESTES" no app.
# Build de producao NAO passa isto, entao o banner nunca aparece em prod.
$defines += "--dart-define=APP_ENV=staging"

Write-Host "==> Rodando contra STAGING: $($vars['SUPABASE_URL'])" -ForegroundColor Cyan
flutter run -d chrome @defines
