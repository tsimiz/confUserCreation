# Conference User Creation Script

A PowerShell script to create conference workshop user accounts in an Azure tenant. This script automatically discovers the current Azure tenant and creates a specified number of Entra ID users with a standardized naming pattern. It also includes functionality to create Entra ID groups and Azure resource groups for enhanced organization and access control.

## Features

- **Automatic Tenant Discovery**: Automatically detects and uses the current Azure tenant
- **Standardized Naming**: Creates users with pattern `<ConferenceName>-user1`, `<ConferenceName>-user2`, etc.
- **Entra ID Group Management**: Creates and manages Entra ID groups for conference users
- **Azure Resource Groups**: Optionally creates individual resource groups for each user
- **Flexible Configuration**: Customizable user count, domain, and password settings
- **Error Handling**: Robust error handling with detailed logging
- **Security**: Uses Microsoft Graph API with proper authentication and permissions
- **Cleanup Support**: Includes deletion script for removing created resources

## Prerequisites

### PowerShell Modules
Install the required Microsoft Graph PowerShell modules:

```powershell
Install-Module Microsoft.Graph.Authentication -Force
Install-Module Microsoft.Graph.Users -Force
Install-Module Microsoft.Graph.Groups -Force
```

For Azure resource group functionality, also install:
```powershell
Install-Module Az.Accounts -Force
Install-Module Az.Resources -Force
```

### Azure Permissions
The user running the script must have sufficient permissions in the Azure tenant:
- **User.ReadWrite.All**: To create and manage users
- **Directory.Read.All**: To read tenant information
- **Group.ReadWrite.All**: To create and manage groups

For Azure resource group creation:
- **Contributor** or **Owner** role in the target subscription

### Authentication
You must be authenticated to Azure with appropriate permissions. The script will prompt for authentication when run.

## Usage

### Creating Users

#### Basic Usage
```powershell
.\New-ConferenceUsers.ps1 -ConferenceName "TechConf2024" -UserCount 15
```

#### Advanced Usage
```powershell
# Create users with custom password
.\New-ConferenceUsers.ps1 -ConferenceName "DevWorkshop" -UserCount 5 -Password "TempPass123!"

# Create users with custom domain
.\New-ConferenceUsers.ps1 -ConferenceName "CloudSummit" -UserCount 20 -Domain "contoso.com"

# Create users without forcing password change
.\New-ConferenceUsers.ps1 -ConferenceName "SecureConf" -UserCount 10 -ForcePasswordChange $false

# Create users with Azure resource groups
.\New-ConferenceUsers.ps1 -ConferenceName "TechConf2024" -UserCount 10 -CreateResourceGroups $true -Location "East US"

# Create users with Azure resource groups in specific subscription
.\New-ConferenceUsers.ps1 -ConferenceName "DevWorkshop" -UserCount 5 -CreateResourceGroups $true -SubscriptionId "12345678-1234-1234-1234-123456789012" -Location "West Europe"
```

### Removing Users

#### Basic Removal
```powershell
.\Remove-ConferenceUsers.ps1 -ConferenceName "TechConf2024"
```

#### Advanced Removal
```powershell
# Remove users and groups but not resource groups
.\Remove-ConferenceUsers.ps1 -ConferenceName "DevWorkshop" -RemoveResourceGroups $false

# Remove everything including resource groups without confirmation
.\Remove-ConferenceUsers.ps1 -ConferenceName "TechConf2024" -RemoveResourceGroups $true -Force

# Remove users from specific domain
.\Remove-ConferenceUsers.ps1 -ConferenceName "CloudSummit" -Domain "contoso.com"
```

## Parameters

### New-ConferenceUsers.ps1

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `ConferenceName` | String | Yes | - | Conference name used as username prefix |
| `UserCount` | Integer | No | 10 | Number of users to create (1-1000) |
| `Domain` | String | No | Auto-detected | Domain for user principal names |
| `Password` | String | No | Auto-generated | Initial password for all users |
| `ForcePasswordChange` | Boolean | No | $true | Force password change on first login |
| `CreateResourceGroups` | Boolean | No | $false | Create Azure resource groups for each user |
| `SubscriptionId` | String | No | Current context | Azure subscription ID for resource groups |
| `Location` | String | No | Interactive selection | Azure location for resource groups |

### Remove-ConferenceUsers.ps1

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `ConferenceName` | String | Yes | - | Conference name to identify users to remove |
| `Domain` | String | No | Auto-detected | Domain for user principal names |
| `RemoveGroups` | Boolean | No | $true | Remove associated Entra ID group |
| `RemoveResourceGroups` | Boolean | No | $false | Remove associated Azure resource groups |
| `Force` | Switch | No | $false | Skip confirmation prompts |

## Examples

### Example 1: Basic Conference Setup
```powershell
.\New-ConferenceUsers.ps1 -ConferenceName "TechConf2024" -UserCount 25
```
**Output**: Creates 25 users named TechConf2024-user1 through TechConf2024-user25 and an Entra ID group "TechConf2024-users"

### Example 2: Custom Password
```powershell
.\New-ConferenceUsers.ps1 -ConferenceName "DevWorkshop" -UserCount 10 -Password "Workshop2024!"
```
**Output**: Creates 10 users with the specified password and Entra ID group

### Example 3: Large Conference with Resource Groups
```powershell
.\New-ConferenceUsers.ps1 -ConferenceName "GlobalSummit" -UserCount 100 -Domain "company.com" -CreateResourceGroups $true -Location "East US"
```
**Output**: Creates 100 users using the specified domain, creates individual resource groups for each user in East US

### Example 4: Complete Cleanup
```powershell
.\Remove-ConferenceUsers.ps1 -ConferenceName "TechConf2024" -RemoveResourceGroups $true
```
**Output**: Removes all users, groups, and resource groups associated with TechConf2024

## Output

The script provides detailed output including:
- Connection status to Microsoft Graph
- Tenant information (name and ID)
- Domain being used for user creation
- Progress of user creation
- Summary of successful and failed creations
- Complete list of created users
- Login credentials for the users

### Sample Output
```
=== Conference User Creation Script ===
Conference Name: TechConf2024
User Count: 5

Checking for required PowerShell modules...
Importing module: Microsoft.Graph.Authentication
Importing module: Microsoft.Graph.Users
Connecting to Microsoft Graph...
Successfully connected to Microsoft Graph
Retrieving tenant information...
Connected to tenant: Contoso Corporation
Tenant ID: 12345678-1234-1234-1234-123456789012
Using domain: contoso.com
Generated password: Kj8#mN2pQ7wX
IMPORTANT: Save this password - it will be used for all created users!

Creating 5 users...
Creating user 1 of 5: TechConf2024-user1@contoso.com
✓ Created user: TechConf2024-user1@contoso.com
Creating user 2 of 5: TechConf2024-user2@contoso.com
✓ Created user: TechConf2024-user2@contoso.com
...

=== Creation Summary ===
Successfully created: 5 out of 5 users
Failed: 0 users

Created Users:
==============
• TechConf2024 Workshop User 1 (TechConf2024-user1@contoso.com)
• TechConf2024 Workshop User 2 (TechConf2024-user2@contoso.com)
...

Login Information:
Username Format: TechConf2024-user[1-5]@contoso.com
Password: Kj8#mN2pQ7wX
Force Password Change: True

Script completed successfully!
```

## Security Considerations

- **Password Management**: If no password is specified, a random password is generated and displayed. Make sure to save this password securely.
- **Permissions**: The script requires high-level permissions to create users. Ensure the running user has appropriate access.
- **Audit Trail**: User creation activities are logged in Azure AD audit logs.
- **Password Policy**: Generated passwords comply with common complexity requirements, but ensure they meet your organization's password policy.

## Troubleshooting

### Common Issues

1. **Module Not Found**
   ```
   Error: Required module 'Microsoft.Graph.Authentication' is not installed
   ```
   **Solution**: Install the required modules using `Install-Module`

2. **Insufficient Permissions**
   ```
   Error: Insufficient privileges to complete the operation
   ```
   **Solution**: Ensure the user has User.ReadWrite.All and Directory.Read.All permissions

3. **Authentication Failed**
   ```
   Error: Failed to connect to Microsoft Graph
   ```
   **Solution**: Check your Azure credentials and network connectivity

4. **Domain Not Found**
   ```
   Error: The domain 'example.com' is not verified in this tenant
   ```
   **Solution**: Use a verified domain or let the script auto-detect the default domain

### Getting Help

For additional help with the script parameters:
```powershell
Get-Help .\New-ConferenceUsers.ps1 -Full
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and questions, please create an issue in the GitHub repository.