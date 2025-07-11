# Conference User Creation - Web Frontend

A locally running Python Flask web frontend for the Conference User Creation PowerShell scripts. This web interface provides a user-friendly way to generate PowerShell commands for creating and managing conference workshop user accounts in Azure/Entra ID environments.

## Features

- **User-Friendly Forms**: Web-based forms for all PowerShell script parameters
- **Real-Time Validation**: Form validation with immediate feedback
- **Command Generation**: Generates exact PowerShell commands with proper syntax
- **Copy to Clipboard**: One-click copying of generated commands
- **Responsive Design**: Works on desktop and mobile devices
- **Safety Features**: Built-in warnings and confirmation steps for removal operations
- **Professional UI**: Bootstrap-based interface with modern styling

## Quick Start

### Prerequisites

- Python 3.7 or higher
- pip (Python package installer)

### Installation

1. **Navigate to the repository directory:**
   ```bash
   cd confUserCreation
   ```

2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

### Running the Web Frontend

1. **Start the Flask application:**
   ```bash
   python app.py
   ```

2. **Open your web browser and navigate to:**
   ```
   http://localhost:5000
   ```

3. **Use the web interface to:**
   - Create conference users by filling out the creation form
   - Remove conference users by filling out the removal form
   - Copy the generated PowerShell commands
   - Run the commands in your PowerShell environment

## Web Interface Overview

### Home Page
- Overview of available operations
- Links to create and remove user forms
- Information about prerequisites and how it works

### Create Users Form
- **Basic Configuration**: Conference name, user count, domain, password settings
- **Azure Resource Groups**: Options for creating individual resource groups
- **Advanced Options**: Excel output path, dry run mode
- **Validation**: Real-time form validation with helpful error messages

### Remove Users Form
- **Basic Configuration**: Conference name and domain
- **Removal Options**: Choose what to remove (users, groups, resource groups)
- **Execution Options**: Dry run and force mode settings
- **Safety Features**: Multiple confirmation checkboxes and warnings

### Command Result Page
- **Generated Command**: Formatted PowerShell command ready to copy
- **Copy Button**: One-click copying to clipboard
- **Next Steps**: Clear instructions on how to use the command
- **Context Information**: Shows what the command will do

### About Page
- Detailed information about features and prerequisites
- PowerShell module installation instructions
- Required Azure permissions
- Security considerations and limitations

## Form Parameters

### User Creation Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| Conference Name | Used as username prefix | Yes | - |
| User Count | Number of users to create (1-1000) | No | 10 |
| Domain | Domain for user principal names | No | Auto-detected |
| Password | Initial password for users | No | Auto-generated |
| Force Password Change | Require password change on first login | No | True |
| Create Resource Groups | Create individual Azure resource groups | No | False |
| Subscription ID | Azure subscription for resource groups | No | Current context |
| Location | Azure location for resource groups | No | Interactive selection |
| Excel Output Path | Directory for Excel export | No | Current directory |
| Dry Run | Preview mode without creating resources | No | False |

### User Removal Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| Conference Name | Conference to identify users for removal | Yes | - |
| Domain | Domain for user principal names | No | Auto-detected |
| Remove Groups | Remove associated Entra ID groups | No | True |
| Remove Resource Groups | Remove associated Azure resource groups | No | False |
| Force | Skip confirmation prompts | No | False |
| Dry Run | Preview mode without removing resources | No | False |

## Security Features

- **Input Validation**: All form inputs are validated for format and security
- **XSS Protection**: Templates use automatic escaping
- **CSRF Protection**: Flask secret key for session security
- **Safe Defaults**: Secure default values for all options
- **Warning Messages**: Clear warnings for destructive operations

## Development

### File Structure
```
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── templates/            # HTML templates
│   ├── base.html         # Base template with navigation
│   ├── index.html        # Home page
│   ├── create_users.html # User creation form
│   ├── remove_users.html # User removal form
│   ├── command_result.html # Generated command display
│   └── about.html        # About page
└── static/               # Static assets
    ├── css/
    │   └── style.css     # Custom styling
    └── js/
        └── script.js     # JavaScript functionality
```

### Customization

The web frontend can be customized by modifying:

- **Styling**: Edit `static/css/style.css` for visual changes
- **Functionality**: Modify `static/js/script.js` for client-side behavior
- **Templates**: Update HTML templates in `templates/` directory
- **Validation**: Adjust validation rules in `app.py`

### Development Mode

Run the application in development mode with debug enabled:

```bash
python app.py
```

The application will:
- Run on `http://localhost:5000`
- Enable debug mode with auto-reload
- Show detailed error messages
- Allow access from any IP address (`0.0.0.0`)

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```
   Error: Address already in use
   ```
   Solution: Change the port in `app.py` or kill the process using port 5000

2. **Module Not Found**
   ```
   ModuleNotFoundError: No module named 'flask'
   ```
   Solution: Install requirements with `pip install -r requirements.txt`

3. **Permission Denied**
   ```
   PermissionError: [Errno 13] Permission denied
   ```
   Solution: Run with appropriate permissions or use a different port

### Browser Compatibility

The web frontend is tested and compatible with:
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

For best experience, use a modern browser with JavaScript enabled.

## Support

For issues related to the web frontend:
1. Check the console output for error messages
2. Verify all dependencies are installed correctly
3. Ensure you're using a supported Python version
4. Check the GitHub repository for known issues

For issues related to the PowerShell scripts themselves, refer to the main README.md file.

## License

This web frontend is part of the Conference User Creation project and is licensed under the MIT License. See the LICENSE file for details.