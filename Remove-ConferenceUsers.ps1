<#
.SYNOPSIS
    Removes conference workshop user accounts and associated resources from an Azure tenant.

.DESCRIPTION
    This script removes conference users created by New-ConferenceUsers.ps1 script.
    It can remove users matching the pattern <ConferenceName>-user*, associated Entra ID groups,
    and optionally associated Azure resource groups.

.PARAMETER ConferenceName
    The name of the conference. This will be used to identify users with the pattern
    <ConferenceName>-user1, <ConferenceName>-user2, etc.

.PARAMETER Domain
    The domain to search for user principal names. If not specified, the script will use
    the default domain of the current tenant.

.PARAMETER RemoveGroups
    Whether to also remove the associated Entra ID group. Default is $true.

.PARAMETER RemoveResourceGroups
    Whether to also remove associated Azure resource groups. Default is $false.
    Requires Azure PowerShell modules and appropriate permissions.

.PARAMETER Force
    Skip confirmation prompts and proceed with deletion. Use with caution.

.EXAMPLE
    .\Remove-ConferenceUsers.ps1 -ConferenceName "TechConf2024"
    
    Removes all users matching TechConf2024-user* pattern and asks for confirmation

.EXAMPLE
    .\Remove-ConferenceUsers.ps1 -ConferenceName "DevWorkshop" -RemoveResourceGroups $true
    
    Removes users and also removes associated Azure resource groups

.NOTES
    Prerequisites:
    - Microsoft.Graph PowerShell module must be installed
    - User must be authenticated with sufficient privileges to delete users and groups
    - Required permissions: User.ReadWrite.All, Group.ReadWrite.All
    - For resource group deletion: Az.Accounts, Az.Resources modules and appropriate Azure permissions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Conference name to identify users to remove")]
    [ValidateNotNullOrEmpty()]
    [string]$ConferenceName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Domain for user principal names")]
    [string]$Domain,
    
    [Parameter(Mandatory = $false, HelpMessage = "Remove associated Entra ID group")]
    [bool]$RemoveGroups = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "Remove associated Azure resource groups")]
    [bool]$RemoveResourceGroups = $false,
    
    [Parameter(Mandatory = $false, HelpMessage = "Skip confirmation prompts")]
    [switch]$Force
)

# Import required modules
function Import-RequiredModules {
    Write-Host "Checking for required PowerShell modules..." -ForegroundColor Yellow
    
    $requiredModules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Users", "Microsoft.Graph.Groups")
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Error "Required module '$module' is not installed. Please install it using: Install-Module $module"
            exit 1
        }
        
        if (!(Get-Module -Name $module)) {
            Write-Host "Importing module: $module" -ForegroundColor Green
            Import-Module $module -Force
        }
    }
    
    # Import Azure modules if resource group removal is requested
    if ($RemoveResourceGroups) {
        $azureModules = @("Az.Accounts", "Az.Resources")
        
        foreach ($module in $azureModules) {
            if (!(Get-Module -ListAvailable -Name $module)) {
                Write-Error "Required Azure module '$module' is not installed. Please install it using: Install-Module $module"
                Write-Error "Azure modules are required for resource group removal."
                exit 1
            }
            
            if (!(Get-Module -Name $module)) {
                Write-Host "Importing Azure module: $module" -ForegroundColor Green
                Import-Module $module -Force
            }
        }
    }
}

# Connect to Microsoft Graph
function Connect-ToGraph {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    
    try {
        # Connect with required scopes
        $scopes = @("User.ReadWrite.All", "Directory.Read.All", "Group.ReadWrite.All")
        Connect-MgGraph -Scopes $scopes -NoWelcome
        Write-Host "Successfully connected to Microsoft Graph" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        exit 1
    }
}

# Connect to Azure if needed
function Connect-ToAzure {
    if (!$RemoveResourceGroups) {
        return
    }
    
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    
    try {
        # Check if already connected
        $context = Get-AzContext
        if (!$context) {
            Connect-AzAccount
        }
        Write-Host "Successfully connected to Azure" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
        Write-Warning "Resource group removal will be skipped."
        $script:RemoveResourceGroups = $false
    }
}

# Get current tenant information
function Get-TenantInfo {
    Write-Host "Retrieving tenant information..." -ForegroundColor Yellow
    
    try {
        $context = Get-MgContext
        $tenant = Get-MgOrganization
        
        Write-Host "Connected to tenant: $($tenant.DisplayName)" -ForegroundColor Green
        Write-Host "Tenant ID: $($context.TenantId)" -ForegroundColor Green
        
        return @{
            TenantId = $context.TenantId
            TenantName = $tenant.DisplayName
            DefaultDomain = ($tenant.VerifiedDomains | Where-Object { $_.IsDefault -eq $true }).Name
        }
    }
    catch {
        Write-Error "Failed to retrieve tenant information: $($_.Exception.Message)"
        exit 1
    }
}

# Find conference users
function Find-ConferenceUsers {
    param(
        [string]$ConferenceName,
        [string]$UserDomain
    )
    
    Write-Host "Searching for conference users..." -ForegroundColor Yellow
    
    try {
        $filterPattern = "$ConferenceName-user"
        $users = Get-MgUser -All | Where-Object { 
            $_.UserPrincipalName -like "*$filterPattern*@$UserDomain" -or 
            $_.DisplayName -like "*$ConferenceName*" 
        }
        
        return $users
    }
    catch {
        Write-Error "Failed to search for users: $($_.Exception.Message)"
        return @()
    }
}

# Find conference group
function Find-ConferenceGroup {
    param(
        [string]$ConferenceName
    )
    
    Write-Host "Searching for conference group..." -ForegroundColor Yellow
    
    try {
        $groupName = "$ConferenceName-users"
        $groups = Get-MgGroup -All | Where-Object { $_.DisplayName -eq $groupName }
        
        return $groups
    }
    catch {
        Write-Error "Failed to search for groups: $($_.Exception.Message)"
        return @()
    }
}

# Find conference resource groups
function Find-ConferenceResourceGroups {
    param(
        [string]$ConferenceName
    )
    
    if (!$RemoveResourceGroups) {
        return @()
    }
    
    Write-Host "Searching for conference resource groups..." -ForegroundColor Yellow
    
    try {
        $filterPattern = "rg-$ConferenceName-user"
        $resourceGroups = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "$filterPattern*" }
        
        return $resourceGroups
    }
    catch {
        Write-Error "Failed to search for resource groups: $($_.Exception.Message)"
        return @()
    }
}

# Remove users
function Remove-ConferenceUsers {
    param(
        [array]$Users
    )
    
    if ($Users.Count -eq 0) {
        Write-Host "No users to remove." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Removing $($Users.Count) users..." -ForegroundColor Yellow
    
    $successCount = 0
    foreach ($user in $Users) {
        try {
            Write-Host "Removing user: $($user.UserPrincipalName)" -ForegroundColor Cyan
            Remove-MgUser -UserId $user.Id -Confirm:$false
            Write-Host "✓ Removed user: $($user.UserPrincipalName)" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Warning "Failed to remove user $($user.UserPrincipalName): $($_.Exception.Message)"
        }
        
        # Add small delay to avoid throttling
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host "Successfully removed $successCount out of $($Users.Count) users" -ForegroundColor Green
}

# Remove groups
function Remove-ConferenceGroups {
    param(
        [array]$Groups
    )
    
    if ($Groups.Count -eq 0) {
        Write-Host "No groups to remove." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Removing $($Groups.Count) groups..." -ForegroundColor Yellow
    
    foreach ($group in $Groups) {
        try {
            Write-Host "Removing group: $($group.DisplayName)" -ForegroundColor Cyan
            Remove-MgGroup -GroupId $group.Id -Confirm:$false
            Write-Host "✓ Removed group: $($group.DisplayName)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to remove group $($group.DisplayName): $($_.Exception.Message)"
        }
    }
}

# Remove resource groups
function Remove-ConferenceResourceGroups {
    param(
        [array]$ResourceGroups
    )
    
    if ($ResourceGroups.Count -eq 0) {
        Write-Host "No resource groups to remove." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Removing $($ResourceGroups.Count) resource groups..." -ForegroundColor Yellow
    
    foreach ($rg in $ResourceGroups) {
        try {
            Write-Host "Removing resource group: $($rg.ResourceGroupName)" -ForegroundColor Cyan
            Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force -AsJob | Out-Null
            Write-Host "✓ Started removal of resource group: $($rg.ResourceGroupName)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to remove resource group $($rg.ResourceGroupName): $($_.Exception.Message)"
        }
    }
    
    Write-Host "Note: Resource group removals are running as background jobs" -ForegroundColor Yellow
}

# Main execution
function Main {
    Write-Host "=== Conference User Removal Script ===" -ForegroundColor Cyan
    Write-Host "Conference Name: $ConferenceName" -ForegroundColor White
    Write-Host "Remove Groups: $RemoveGroups" -ForegroundColor White
    Write-Host "Remove Resource Groups: $RemoveResourceGroups" -ForegroundColor White
    Write-Host ""
    
    # Import required modules
    Import-RequiredModules
    
    # Connect to Microsoft Graph
    Connect-ToGraph
    
    # Connect to Azure if needed
    Connect-ToAzure
    
    # Get tenant information
    $tenantInfo = Get-TenantInfo
    
    # Determine domain to use
    $userDomain = if ($Domain) { $Domain } else { $tenantInfo.DefaultDomain }
    Write-Host "Using domain: $userDomain" -ForegroundColor Green
    Write-Host ""
    
    # Find resources to remove
    $users = Find-ConferenceUsers -ConferenceName $ConferenceName -UserDomain $userDomain
    $groups = if ($RemoveGroups) { Find-ConferenceGroup -ConferenceName $ConferenceName } else { @() }
    $resourceGroups = Find-ConferenceResourceGroups -ConferenceName $ConferenceName
    
    # Display summary
    Write-Host "=== Removal Summary ===" -ForegroundColor Cyan
    Write-Host "Users found: $($users.Count)" -ForegroundColor White
    Write-Host "Groups found: $($groups.Count)" -ForegroundColor White
    Write-Host "Resource Groups found: $($resourceGroups.Count)" -ForegroundColor White
    Write-Host ""
    
    if ($users.Count -eq 0 -and $groups.Count -eq 0 -and $resourceGroups.Count -eq 0) {
        Write-Host "No resources found to remove." -ForegroundColor Yellow
        Write-Host "Script completed." -ForegroundColor Green
        return
    }
    
    # Show what will be removed
    if ($users.Count -gt 0) {
        Write-Host "Users to be removed:" -ForegroundColor Yellow
        foreach ($user in $users) {
            Write-Host "  • $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($groups.Count -gt 0) {
        Write-Host "Groups to be removed:" -ForegroundColor Yellow
        foreach ($group in $groups) {
            Write-Host "  • $($group.DisplayName)" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($resourceGroups.Count -gt 0) {
        Write-Host "Resource Groups to be removed:" -ForegroundColor Yellow
        foreach ($rg in $resourceGroups) {
            Write-Host "  • $($rg.ResourceGroupName) ($($rg.Location))" -ForegroundColor White
        }
        Write-Host ""
    }
    
    # Confirmation
    if (!$Force) {
        $confirmation = Read-Host "Do you want to proceed with the removal? (y/N)"
        if ($confirmation -notmatch '^[Yy]') {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    Write-Host ""
    Write-Host "Proceeding with removal..." -ForegroundColor Red
    Write-Host ""
    
    # Remove resources
    Remove-ConferenceUsers -Users $users
    if ($RemoveGroups) {
        Remove-ConferenceGroups -Groups $groups
    }
    if ($RemoveResourceGroups) {
        Remove-ConferenceResourceGroups -ResourceGroups $resourceGroups
    }
    
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph | Out-Null
    Write-Host ""
    Write-Host "Script completed successfully!" -ForegroundColor Green
}

# Execute main function
try {
    Main
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}