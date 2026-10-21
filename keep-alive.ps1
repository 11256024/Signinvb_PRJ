# ============================================================================
# Supabase Daily Keep-Alive & Windows Scheduled Task Installer (keep-alive.ps1)
# - Run directly: Sends a query to wake up Supabase immediately
# - Run with -InstallSchedule: Registers a daily Windows Scheduled Task (09:00 AM)
# ============================================================================

param (
    [switch]$InstallSchedule
)

$SupabaseRestUrl = "https://mtorunczoyjvhmufaast.supabase.co/rest/v1/team_users?select=id&limit=1"
$SupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10b3J1bmN6b3lqdmhtdWZhYXN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI1MTA5ODksImV4cCI6MjEwODA4Njk4OX0.ewbVgqhfJy5qWFXaI0awcefX_iOZYjK_Ly9wcFZyt5Q"

if ($InstallSchedule) {
    $TaskName = "Supabase_KeepAlive_Signinvb"
    $ScriptPath = $MyInvocation.MyCommand.Path
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
    $Trigger = New-ScheduledTaskTrigger -Daily -At 9:00AM
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Daily ping to keep Supabase database active" -Force | Out-Null
    Write-Host "[OK] Scheduled Task '$TaskName' registered (runs daily at 09:00 AM)." -ForegroundColor Green
}

try {
    $Headers = @{
        "apikey"        = $SupabaseAnonKey
        "Authorization" = "Bearer $SupabaseAnonKey"
    }
    $Response = Invoke-RestMethod -Uri $SupabaseRestUrl -Headers $Headers -Method Get -TimeoutSec 20
    $TimeStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$TimeStr] Supabase Keep-Alive OK! Response: $($Response | ConvertTo-Json -Compress)" -ForegroundColor Cyan
} catch {
    $TimeStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$TimeStr] Supabase Keep-Alive FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
