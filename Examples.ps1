# Example Usage Script for Conference User Creation and Removal
# This script demonstrates how to use the New-ConferenceUsers.ps1 and Remove-ConferenceUsers.ps1 scripts

Write-Host "=== Conference User Creation and Removal - Example Usage ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "========== USER CREATION EXAMPLES ==========" -ForegroundColor Magenta
Write-Host ""

# Example 1: Basic usage with default settings
Write-Host "Example 1: Basic usage" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'TechConf2024' -UserCount 5" -ForegroundColor White
Write-Host "This creates 5 users: TechConf2024-user1 through TechConf2024-user5 and an Entra ID group" -ForegroundColor Gray
Write-Host ""

# Example 2: Custom password
Write-Host "Example 2: With custom password" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'DevWorkshop' -UserCount 3 -Password 'Workshop2024!'" -ForegroundColor White
Write-Host "This creates 3 users with the specified password and Entra ID group" -ForegroundColor Gray
Write-Host ""

# Example 3: Large conference
Write-Host "Example 3: Large conference setup" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'GlobalSummit' -UserCount 50 -Domain 'company.com'" -ForegroundColor White
Write-Host "This creates 50 users using a specific domain and Entra ID group" -ForegroundColor Gray
Write-Host ""

# Example 4: No password change required
Write-Host "Example 4: No forced password change" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'SecureConf' -UserCount 10 -ForcePasswordChange \$false" -ForegroundColor White
Write-Host "This creates 10 users who won't be forced to change password on first login" -ForegroundColor Gray
Write-Host ""

# Example 5: With Azure resource groups
Write-Host "Example 5: With Azure resource groups" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'TechConf2024' -UserCount 10 -CreateResourceGroups \$true -Location 'East US'" -ForegroundColor White
Write-Host "This creates users, Entra ID group, and individual resource groups for each user in East US" -ForegroundColor Gray
Write-Host ""

# Example 6: Full setup with subscription
Write-Host "Example 6: Full setup with specific subscription" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'DevWorkshop' -UserCount 5 -CreateResourceGroups \$true -SubscriptionId '12345678-1234-1234-1234-123456789012' -Location 'West Europe'" -ForegroundColor White
Write-Host "This creates users, group, and resource groups in a specific subscription and location" -ForegroundColor Gray
Write-Host ""

# Example 6a: Dry run preview
Write-Host "Example 6a: Dry run preview" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'TechConf2024' -UserCount 10 -DryRun" -ForegroundColor White
Write-Host "This shows what would be created without actually creating anything, then asks for confirmation" -ForegroundColor Gray
Write-Host ""

# Example 6b: Dry run with resource groups
Write-Host "Example 6b: Dry run with resource groups" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'DevWorkshop' -UserCount 5 -CreateResourceGroups \$true -Location 'East US' -DryRun" -ForegroundColor White
Write-Host "This shows what users and resources groups would be created, then asks for confirmation" -ForegroundColor Gray
Write-Host ""

# Example 6c: Excel output to custom folder
Write-Host "Example 6c: Excel output to custom folder" -ForegroundColor Yellow
Write-Host "Command: .\New-ConferenceUsers.ps1 -ConferenceName 'TechConf2024' -UserCount 20 -ExcelOutputPath 'C:\Conference\Reports'" -ForegroundColor White
Write-Host "This creates users and saves detailed Excel report to specified folder with usernames, passwords, and resource groups" -ForegroundColor Gray
Write-Host ""

Write-Host "========== USER REMOVAL EXAMPLES ==========" -ForegroundColor Magenta
Write-Host ""

# Example 7: Basic removal
Write-Host "Example 7: Basic removal" -ForegroundColor Yellow
Write-Host "Command: .\Remove-ConferenceUsers.ps1 -ConferenceName 'TechConf2024'" -ForegroundColor White
Write-Host "This removes all TechConf2024 users and associated Entra ID group (with confirmation)" -ForegroundColor Gray
Write-Host ""

# Example 8: Remove everything including resource groups
Write-Host "Example 8: Complete cleanup" -ForegroundColor Yellow
Write-Host "Command: .\Remove-ConferenceUsers.ps1 -ConferenceName 'DevWorkshop' -RemoveResourceGroups \$true" -ForegroundColor White
Write-Host "This removes users, groups, and resource groups (with confirmation)" -ForegroundColor Gray
Write-Host ""

# Example 9: Force removal without confirmation
Write-Host "Example 9: Force removal without confirmation" -ForegroundColor Yellow
Write-Host "Command: .\Remove-ConferenceUsers.ps1 -ConferenceName 'TechConf2024' -RemoveResourceGroups \$true -Force" -ForegroundColor White
Write-Host "This removes everything without asking for confirmation (use with caution!)" -ForegroundColor Gray
Write-Host ""

# Example 10: Remove from specific domain
Write-Host "Example 10: Remove from specific domain" -ForegroundColor Yellow
Write-Host "Command: .\Remove-ConferenceUsers.ps1 -ConferenceName 'GlobalSummit' -Domain 'company.com'" -ForegroundColor White
Write-Host "This removes users from a specific domain only" -ForegroundColor Gray
Write-Host ""

# Example 10a: Dry run removal preview
Write-Host "Example 10a: Dry run removal preview" -ForegroundColor Yellow
Write-Host "Command: .\Remove-ConferenceUsers.ps1 -ConferenceName 'TechConf2024' -DryRun" -ForegroundColor White
Write-Host "This shows what would be removed without actually removing anything, then asks for confirmation" -ForegroundColor Gray
Write-Host ""

# Example 10b: Dry run with resource groups
Write-Host "Example 10b: Dry run with resource groups" -ForegroundColor Yellow
Write-Host "Command: .\Remove-ConferenceUsers.ps1 -ConferenceName 'DevWorkshop' -RemoveResourceGroups \$true -DryRun" -ForegroundColor White
Write-Host "This shows what users, groups, and resource groups would be removed, then asks for confirmation" -ForegroundColor Gray
Write-Host ""

Write-Host "Prerequisites:" -ForegroundColor Green
Write-Host "For basic functionality:" -ForegroundColor White
Write-Host "  1. Install-Module Microsoft.Graph.Authentication -Force" -ForegroundColor White
Write-Host "  2. Install-Module Microsoft.Graph.Users -Force" -ForegroundColor White
Write-Host "  3. Install-Module Microsoft.Graph.Groups -Force" -ForegroundColor White
Write-Host "For Azure resource groups:" -ForegroundColor White
Write-Host "  4. Install-Module Az.Accounts -Force" -ForegroundColor White
Write-Host "  5. Install-Module Az.Resources -Force" -ForegroundColor White
Write-Host "For Excel output (optional but recommended):" -ForegroundColor White
Write-Host "  6. Install-Module ImportExcel -Force" -ForegroundColor White
Write-Host "Permissions needed:" -ForegroundColor White
Write-Host "  - User.ReadWrite.All, Directory.Read.All, Group.ReadWrite.All" -ForegroundColor White
Write-Host "  - Contributor/Owner role in Azure subscription (for resource groups)" -ForegroundColor White
Write-Host ""

Write-Host "To get detailed help, run:" -ForegroundColor Green
Write-Host "Get-Help .\New-ConferenceUsers.ps1 -Full" -ForegroundColor White
Write-Host "Get-Help .\Remove-ConferenceUsers.ps1 -Full" -ForegroundColor White