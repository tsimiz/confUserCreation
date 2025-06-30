<#
.SYNOPSIS
    Creates conference workshop user accounts in an Azure tenant.

.DESCRIPTION
    This script creates a specified number of Entra ID user accounts for conference workshops.
    It automatically detects the current Azure tenant and creates users with a standardized
    naming pattern: <ConferenceName>-user1, <ConferenceName>-user2, etc.

.PARAMETER ConferenceName
    The name of the conference. This will be used as a prefix for usernames.
    Example: "TechConf2024" will create users like "TechConf2024-user1"

.PARAMETER UserCount
    The number of users to create. Default is 10.

.PARAMETER Domain
    The domain to use for user principal names. If not specified, the script will use
    the default domain of the current tenant.

.PARAMETER Password
    The initial password for all created users. If not specified, a random password
    will be generated and displayed.

.PARAMETER ForcePasswordChange
    Whether users should be forced to change their password on first login. Default is $true.

.EXAMPLE
    .\New-ConferenceUsers.ps1 -ConferenceName "TechConf2024" -UserCount 15
    
    Creates 15 users with names TechConf2024-user1 through TechConf2024-user15

.EXAMPLE
    .\New-ConferenceUsers.ps1 -ConferenceName "DevWorkshop" -UserCount 5 -Password "TempPass123!"
    
    Creates 5 users with a specific password

.NOTES
    Prerequisites:
    - Microsoft.Graph PowerShell module must be installed
    - User must be authenticated with sufficient privileges to create users
    - Required permissions: User.ReadWrite.All, Directory.ReadWrite.All
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Conference name to use as username prefix")]
    [ValidateNotNullOrEmpty()]
    [string]$ConferenceName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Number of users to create")]
    [ValidateRange(1, 1000)]
    [int]$UserCount = 10,
    
    [Parameter(Mandatory = $false, HelpMessage = "Domain for user principal names")]
    [string]$Domain,
    
    [Parameter(Mandatory = $false, HelpMessage = "Initial password for users")]
    [string]$Password,
    
    [Parameter(Mandatory = $false, HelpMessage = "Force password change on first login")]
    [bool]$ForcePasswordChange = $true
)

# Import required modules
function Import-RequiredModules {
    Write-Host "Checking for required PowerShell modules..." -ForegroundColor Yellow
    
    $requiredModules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Users")
    
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
}

# Connect to Microsoft Graph
function Connect-ToGraph {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    
    try {
        # Connect with required scopes
        $scopes = @("User.ReadWrite.All", "Directory.Read.All")
        Connect-MgGraph -Scopes $scopes -NoWelcome
        Write-Host "Successfully connected to Microsoft Graph" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        exit 1
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

# Generate random password
function New-RandomPassword {
    param([int]$Length = 12)
    
    $chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$%&*"
    $password = ""
    
    for ($i = 0; $i -lt $Length; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    
    return $password
}

# Create a single user
function New-ConferenceUser {
    param(
        [string]$Username,
        [string]$UserPrincipalName,
        [string]$DisplayName,
        [string]$Password,
        [bool]$ForcePasswordChange
    )
    
    try {
        $passwordProfile = @{
            Password = $Password
            ForceChangePasswordNextSignIn = $ForcePasswordChange
        }
        
        $userParams = @{
            UserPrincipalName = $UserPrincipalName
            DisplayName = $DisplayName
            MailNickname = $Username
            AccountEnabled = $true
            PasswordProfile = $passwordProfile
            UsageLocation = "US"  # Default to US, can be made configurable
        }
        
        $user = New-MgUser -BodyParameter $userParams
        Write-Host "✓ Created user: $($user.UserPrincipalName)" -ForegroundColor Green
        
        return $user
    }
    catch {
        Write-Warning "Failed to create user $UserPrincipalName : $($_.Exception.Message)"
        return $null
    }
}

# Main execution
function Main {
    Write-Host "=== Conference User Creation Script ===" -ForegroundColor Cyan
    Write-Host "Conference Name: $ConferenceName" -ForegroundColor White
    Write-Host "User Count: $UserCount" -ForegroundColor White
    Write-Host ""
    
    # Import required modules
    Import-RequiredModules
    
    # Connect to Microsoft Graph
    Connect-ToGraph
    
    # Get tenant information
    $tenantInfo = Get-TenantInfo
    
    # Determine domain to use
    $userDomain = if ($Domain) { $Domain } else { $tenantInfo.DefaultDomain }
    Write-Host "Using domain: $userDomain" -ForegroundColor Green
    
    # Generate or use provided password
    $userPassword = if ($Password) { $Password } else { New-RandomPassword }
    if (!$Password) {
        Write-Host "Generated password: $userPassword" -ForegroundColor Yellow
        Write-Host "IMPORTANT: Save this password - it will be used for all created users!" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Creating $UserCount users..." -ForegroundColor Yellow
    
    # Create users
    $createdUsers = @()
    $successCount = 0
    
    for ($i = 1; $i -le $UserCount; $i++) {
        $username = "$ConferenceName-user$i"
        $upn = "$username@$userDomain"
        $displayName = "$ConferenceName Workshop User $i"
        
        Write-Host "Creating user $i of $UserCount : $upn" -ForegroundColor Cyan
        
        $user = New-ConferenceUser -Username $username -UserPrincipalName $upn -DisplayName $displayName -Password $userPassword -ForcePasswordChange $ForcePasswordChange
        
        if ($user) {
            $createdUsers += @{
                Username = $username
                UserPrincipalName = $upn
                DisplayName = $displayName
                ObjectId = $user.Id
            }
            $successCount++
        }
        
        # Add small delay to avoid throttling
        Start-Sleep -Milliseconds 500
    }
    
    # Summary
    Write-Host ""
    Write-Host "=== Creation Summary ===" -ForegroundColor Cyan
    Write-Host "Successfully created: $successCount out of $UserCount users" -ForegroundColor Green
    Write-Host "Failed: $($UserCount - $successCount) users" -ForegroundColor Red
    
    if ($createdUsers.Count -gt 0) {
        Write-Host ""
        Write-Host "Created Users:" -ForegroundColor White
        Write-Host "==============" -ForegroundColor White
        
        foreach ($user in $createdUsers) {
            Write-Host "• $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "Login Information:" -ForegroundColor Yellow
        Write-Host "Username Format: $ConferenceName-user[1-$UserCount]@$userDomain" -ForegroundColor White
        Write-Host "Password: $userPassword" -ForegroundColor White
        Write-Host "Force Password Change: $ForcePasswordChange" -ForegroundColor White
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