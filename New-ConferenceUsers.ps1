<#
.SYNOPSIS
    Creates conference workshop user accounts in an Azure tenant.

.DESCRIPTION
    This script creates a specified number of Entra ID user accounts for conference workshops.
    It automatically detects the current Azure tenant and creates users with a standardized
    naming pattern: <ConferenceName>-user1, <ConferenceName>-user2, etc.
    
    The script also creates an Entra ID group for all conference users and optionally
    creates individual Azure resource groups for each user.

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

.PARAMETER CreateResourceGroups
    Whether to create individual Azure resource groups for each user. Default is $false.
    Requires Azure PowerShell modules and appropriate permissions.

.PARAMETER SubscriptionId
    Azure subscription ID where resource groups should be created. If not specified,
    the current subscription context will be used.

.PARAMETER Location
    Azure location where resource groups should be created. If not specified,
    a list of available locations will be presented for selection.

.EXAMPLE
    .\New-ConferenceUsers.ps1 -ConferenceName "TechConf2024" -UserCount 15
    
    Creates 15 users with names TechConf2024-user1 through TechConf2024-user15
    and an Entra ID group "TechConf2024-users"

.EXAMPLE
    .\New-ConferenceUsers.ps1 -ConferenceName "DevWorkshop" -UserCount 5 -Password "TempPass123!" -CreateResourceGroups $true -Location "East US"
    
    Creates 5 users with a specific password, creates resource groups for each user in East US

.NOTES
    Prerequisites:
    - Microsoft.Graph PowerShell module must be installed
    - User must be authenticated with sufficient privileges to create users and groups
    - Required permissions: User.ReadWrite.All, Directory.ReadWrite.All, Group.ReadWrite.All
    - For resource group creation: Az.Accounts, Az.Resources modules and appropriate Azure permissions
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
    [bool]$ForcePasswordChange = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "Create Azure resource groups for each user")]
    [bool]$CreateResourceGroups = $false,
    
    [Parameter(Mandatory = $false, HelpMessage = "Azure subscription ID for resource group creation")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false, HelpMessage = "Azure location for resource groups")]
    [string]$Location
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
    
    # Import Azure modules if resource group creation is requested
    if ($CreateResourceGroups) {
        $azureModules = @("Az.Accounts", "Az.Resources")
        
        foreach ($module in $azureModules) {
            if (!(Get-Module -ListAvailable -Name $module)) {
                Write-Error "Required Azure module '$module' is not installed. Please install it using: Install-Module $module"
                Write-Error "Azure modules are required for resource group creation."
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
    if (!$CreateResourceGroups) {
        return
    }
    
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    
    try {
        # Check if already connected
        $context = Get-AzContext
        if (!$context) {
            Connect-AzAccount
        }
        
        # Set subscription if provided
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
            Write-Host "Set subscription to: $SubscriptionId" -ForegroundColor Green
        }
        
        Write-Host "Successfully connected to Azure" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
        Write-Warning "Resource group creation will be skipped."
        $script:CreateResourceGroups = $false
    }
}

# Get available Azure locations
function Get-AzureLocations {
    try {
        $locations = Get-AzLocation | Select-Object DisplayName, Location | Sort-Object DisplayName
        return $locations
    }
    catch {
        Write-Error "Failed to get Azure locations: $($_.Exception.Message)"
        return @()
    }
}

# Prompt for Azure location if not provided
function Get-ResourceGroupLocation {
    if ($Location) {
        return $Location
    }
    
    if (!$CreateResourceGroups) {
        return $null
    }
    
    Write-Host ""
    Write-Host "Azure location not specified. Available locations:" -ForegroundColor Yellow
    
    $locations = Get-AzureLocations
    if ($locations.Count -eq 0) {
        Write-Warning "Could not retrieve Azure locations. Using 'East US' as default."
        return "East US"
    }
    
    # Display locations with numbers
    for ($i = 0; $i -lt $locations.Count; $i++) {
        Write-Host "$($i + 1). $($locations[$i].DisplayName) ($($locations[$i].Location))" -ForegroundColor White
    }
    
    Write-Host ""
    do {
        $selection = Read-Host "Please select a location by number (1-$($locations.Count))"
        $selectedIndex = $null
        if ([int]::TryParse($selection, [ref]$selectedIndex)) {
            $selectedIndex--
            if ($selectedIndex -ge 0 -and $selectedIndex -lt $locations.Count) {
                $selectedLocation = $locations[$selectedIndex].Location
                Write-Host "Selected location: $($locations[$selectedIndex].DisplayName) ($selectedLocation)" -ForegroundColor Green
                return $selectedLocation
            }
        }
        Write-Host "Invalid selection. Please enter a number between 1 and $($locations.Count)." -ForegroundColor Red
    } while ($true)
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

# Create Entra ID group for conference users
function New-ConferenceGroup {
    param(
        [string]$ConferenceName
    )
    
    $groupName = "$ConferenceName-users"
    $groupDescription = "Conference users group for $ConferenceName"
    
    try {
        # Check if group already exists
        $existingGroup = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
        if ($existingGroup) {
            Write-Host "✓ Group already exists: $groupName" -ForegroundColor Yellow
            return $existingGroup
        }
        
        # Create new group
        $groupParams = @{
            DisplayName = $groupName
            Description = $groupDescription
            MailEnabled = $false
            SecurityEnabled = $true
            MailNickname = $groupName.Replace("-", "").Replace(" ", "")
        }
        
        $group = New-MgGroup -BodyParameter $groupParams
        Write-Host "✓ Created group: $groupName" -ForegroundColor Green
        
        return $group
    }
    catch {
        Write-Warning "Failed to create group $groupName : $($_.Exception.Message)"
        return $null
    }
}

# Add user to conference group
function Add-UserToConferenceGroup {
    param(
        [string]$UserId,
        [string]$GroupId
    )
    
    try {
        $memberParams = @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$UserId"
        }
        
        New-MgGroupMember -GroupId $GroupId -BodyParameter $memberParams
        return $true
    }
    catch {
        Write-Warning "Failed to add user to group: $($_.Exception.Message)"
        return $false
    }
}

# Create Azure resource group for user
function New-UserResourceGroup {
    param(
        [string]$Username,
        [string]$Location,
        [string]$UserId
    )
    
    if (!$CreateResourceGroups) {
        return $null
    }
    
    $resourceGroupName = "rg-$Username"
    
    try {
        # Check if resource group already exists
        $existingRg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
        if ($existingRg) {
            Write-Host "✓ Resource group already exists: $resourceGroupName" -ForegroundColor Yellow
        } else {
            # Create resource group
            $rg = New-AzResourceGroup -Name $resourceGroupName -Location $Location
            Write-Host "✓ Created resource group: $resourceGroupName" -ForegroundColor Green
        }
        
        # Assign user as contributor to the resource group
        try {
            # Get user's object ID for role assignment
            $userObjectId = $UserId
            
            # Assign Contributor role
            New-AzRoleAssignment -ObjectId $userObjectId -RoleDefinitionName "Contributor" -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
            Write-Host "✓ Assigned Contributor role to user for resource group: $resourceGroupName" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to assign role to user for resource group $resourceGroupName : $($_.Exception.Message)"
        }
        
        return $resourceGroupName
    }
    catch {
        Write-Warning "Failed to create resource group $resourceGroupName : $($_.Exception.Message)"
        return $null
    }
}

# Main execution
function Main {
    Write-Host "=== Conference User Creation Script ===" -ForegroundColor Cyan
    Write-Host "Conference Name: $ConferenceName" -ForegroundColor White
    Write-Host "User Count: $UserCount" -ForegroundColor White
    Write-Host "Create Resource Groups: $CreateResourceGroups" -ForegroundColor White
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
    
    # Get resource group location if needed
    $resourceGroupLocation = Get-ResourceGroupLocation
    if ($CreateResourceGroups -and $resourceGroupLocation) {
        Write-Host "Using location for resource groups: $resourceGroupLocation" -ForegroundColor Green
    }
    
    # Generate or use provided password
    $userPassword = if ($Password) { $Password } else { New-RandomPassword }
    if (!$Password) {
        Write-Host "Generated password: $userPassword" -ForegroundColor Yellow
        Write-Host "IMPORTANT: Save this password - it will be used for all created users!" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Create Entra ID group for conference users
    Write-Host "Creating Entra ID group for conference users..." -ForegroundColor Yellow
    $conferenceGroup = New-ConferenceGroup -ConferenceName $ConferenceName
    $groupId = if ($conferenceGroup) { $conferenceGroup.Id } else { $null }
    
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
            # Add user to group
            if ($groupId) {
                $addedToGroup = Add-UserToConferenceGroup -UserId $user.Id -GroupId $groupId
                if ($addedToGroup) {
                    Write-Host "✓ Added user to conference group" -ForegroundColor Green
                }
            }
            
            # Create resource group for user
            $resourceGroupName = $null
            if ($CreateResourceGroups -and $resourceGroupLocation) {
                $resourceGroupName = New-UserResourceGroup -Username $username -Location $resourceGroupLocation -UserId $user.Id
            }
            
            $createdUsers += @{
                Username = $username
                UserPrincipalName = $upn
                DisplayName = $displayName
                ObjectId = $user.Id
                ResourceGroup = $resourceGroupName
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
    
    if ($conferenceGroup) {
        Write-Host "Entra ID Group: $($conferenceGroup.DisplayName)" -ForegroundColor Green
    }
    
    if ($createdUsers.Count -gt 0) {
        Write-Host ""
        Write-Host "Created Users:" -ForegroundColor White
        Write-Host "==============" -ForegroundColor White
        
        foreach ($user in $createdUsers) {
            $rgInfo = if ($user.ResourceGroup) { " [RG: $($user.ResourceGroup)]" } else { "" }
            Write-Host "• $($user.DisplayName) ($($user.UserPrincipalName))$rgInfo" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "Login Information:" -ForegroundColor Yellow
        Write-Host "Username Format: $ConferenceName-user[1-$UserCount]@$userDomain" -ForegroundColor White
        Write-Host "Password: $userPassword" -ForegroundColor White
        Write-Host "Force Password Change: $ForcePasswordChange" -ForegroundColor White
        
        if ($conferenceGroup) {
            Write-Host "Entra ID Group: $($conferenceGroup.DisplayName)" -ForegroundColor White
        }
        
        if ($CreateResourceGroups) {
            Write-Host "Resource Groups: Created individual resource groups for each user" -ForegroundColor White
            Write-Host "Resource Group Location: $resourceGroupLocation" -ForegroundColor White
        }
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