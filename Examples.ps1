# Example Usage Script for Conference User Creation
# This script demonstrates how to use the New-ConferenceUsers.ps1 script

Write-Host "=== Conference User Creation - Example Usage ===" -ForegroundColor Cyan
Write-Host ""

# Example 1: Basic usage with default settings
Write-Host "Example 1: Basic usage" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'TechConf2024' -UserCount 5" -ForegroundColor White
Write-Host "This creates 5 users: TechConf2024-user1 through TechConf2024-user5" -ForegroundColor Gray
Write-Host ""

# Example 2: Custom password
Write-Host "Example 2: With custom password" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'DevWorkshop' -UserCount 3 -Password 'Workshop2024!'" -ForegroundColor White
Write-Host "This creates 3 users with the specified password" -ForegroundColor Gray
Write-Host ""

# Example 3: Large conference
Write-Host "Example 3: Large conference setup" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'GlobalSummit' -UserCount 50 -Domain 'company.com'" -ForegroundColor White
Write-Host "This creates 50 users using a specific domain" -ForegroundColor Gray
Write-Host ""

# Example 4: No password change required
Write-Host "Example 4: No forced password change" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'SecureConf' -UserCount 10 -ForcePasswordChange \$false" -ForegroundColor White
Write-Host "This creates 10 users who won't be forced to change password on first login" -ForegroundColor Gray
Write-Host ""

Write-Host "Prerequisites:" -ForegroundColor Green
Write-Host "1. Install-Module Microsoft.Graph.Authentication -Force" -ForegroundColor White
Write-Host "2. Install-Module Microsoft.Graph.Users -Force" -ForegroundColor White
Write-Host "3. Ensure you have User.ReadWrite.All and Directory.Read.All permissions" -ForegroundColor White
Write-Host ""

Write-Host "To get detailed help, run:" -ForegroundColor Green
Write-Host "Get-Help .\New-ConferenceUsers.ps1 -Full" -ForegroundColor White