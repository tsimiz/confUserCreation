#!/usr/bin/env python3
"""
Flask Web Frontend for Conference User Creation Script

This web application provides a user-friendly interface for generating
PowerShell commands to create and remove conference users in Azure/Entra ID.
"""

from flask import Flask, render_template, request, redirect, url_for, flash
import re
import os

app = Flask(__name__)
app.secret_key = 'conference-user-creation-secret-key'

# Configuration
VALID_AZURE_LOCATIONS = [
    'East US', 'East US 2', 'West US', 'West US 2', 'West US 3',
    'Central US', 'North Central US', 'South Central US', 'West Central US',
    'Canada Central', 'Canada East',
    'Brazil South',
    'North Europe', 'West Europe', 'UK South', 'UK West',
    'France Central', 'Germany West Central', 'Switzerland North',
    'Norway East', 'Sweden Central',
    'Australia East', 'Australia Southeast', 'Australia Central',
    'Japan East', 'Japan West', 'Korea Central', 'Korea South',
    'Southeast Asia', 'East Asia',
    'Central India', 'South India', 'West India',
    'UAE North', 'South Africa North'
]

@app.route('/')
def index():
    """Home page with options to create or remove users."""
    return render_template('index.html')

@app.route('/create', methods=['GET', 'POST'])
def create_users():
    """Form for creating conference users."""
    if request.method == 'POST':
        # Get form data
        conference_name = request.form.get('conference_name', '').strip()
        user_count = request.form.get('user_count', '10')
        domain = request.form.get('domain', '').strip()
        password = request.form.get('password', '').strip()
        force_password_change = request.form.get('force_password_change') == 'true'
        create_resource_groups = request.form.get('create_resource_groups') == 'true'
        subscription_id = request.form.get('subscription_id', '').strip()
        location = request.form.get('location', '').strip()
        dry_run = request.form.get('dry_run') == 'true'
        excel_output_path = request.form.get('excel_output_path', '').strip()
        
        # Validate required fields
        errors = []
        if not conference_name:
            errors.append('Conference Name is required')
        elif not re.match(r'^[a-zA-Z0-9_-]+$', conference_name):
            errors.append('Conference Name must contain only letters, numbers, hyphens, and underscores')
        
        try:
            user_count_int = int(user_count)
            if user_count_int < 1 or user_count_int > 1000:
                errors.append('User Count must be between 1 and 1000')
        except ValueError:
            errors.append('User Count must be a valid number')
        
        if domain and not re.match(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', domain):
            errors.append('Domain must be a valid domain name (e.g., company.com)')
        
        if subscription_id and not re.match(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$', subscription_id):
            errors.append('Subscription ID must be a valid GUID format')
        
        if location and location not in VALID_AZURE_LOCATIONS:
            errors.append('Please select a valid Azure location')
        
        if errors:
            for error in errors:
                flash(error, 'error')
            return render_template('create_users.html', 
                                 locations=VALID_AZURE_LOCATIONS,
                                 form_data=request.form)
        
        # Generate PowerShell command
        powershell_command = generate_create_command(
            conference_name, user_count, domain, password, force_password_change,
            create_resource_groups, subscription_id, location, dry_run, excel_output_path
        )
        
        return render_template('command_result.html', 
                             command=powershell_command,
                             operation='create',
                             conference_name=conference_name,
                             user_count=user_count)
    
    return render_template('create_users.html', locations=VALID_AZURE_LOCATIONS)

@app.route('/remove', methods=['GET', 'POST'])
def remove_users():
    """Form for removing conference users."""
    if request.method == 'POST':
        # Get form data
        conference_name = request.form.get('conference_name', '').strip()
        domain = request.form.get('domain', '').strip()
        remove_groups = request.form.get('remove_groups') == 'true'
        remove_resource_groups = request.form.get('remove_resource_groups') == 'true'
        force = request.form.get('force') == 'true'
        dry_run = request.form.get('dry_run') == 'true'
        
        # Validate required fields
        errors = []
        if not conference_name:
            errors.append('Conference Name is required')
        elif not re.match(r'^[a-zA-Z0-9_-]+$', conference_name):
            errors.append('Conference Name must contain only letters, numbers, hyphens, and underscores')
        
        if domain and not re.match(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', domain):
            errors.append('Domain must be a valid domain name (e.g., company.com)')
        
        if errors:
            for error in errors:
                flash(error, 'error')
            return render_template('remove_users.html', form_data=request.form)
        
        # Generate PowerShell command
        powershell_command = generate_remove_command(
            conference_name, domain, remove_groups, remove_resource_groups, force, dry_run
        )
        
        return render_template('command_result.html', 
                             command=powershell_command,
                             operation='remove',
                             conference_name=conference_name)
    
    return render_template('remove_users.html')

def generate_create_command(conference_name, user_count, domain, password, force_password_change,
                          create_resource_groups, subscription_id, location, dry_run, excel_output_path):
    """Generate PowerShell command for creating users."""
    cmd = f".\\New-ConferenceUsers.ps1 -ConferenceName '{conference_name}' -UserCount {user_count}"
    
    if domain:
        cmd += f" -Domain '{domain}'"
    
    if password:
        cmd += f" -Password '{password}'"
    
    if not force_password_change:
        cmd += " -ForcePasswordChange $false"
    
    if create_resource_groups:
        cmd += " -CreateResourceGroups $true"
        
        if subscription_id:
            cmd += f" -SubscriptionId '{subscription_id}'"
        
        if location:
            cmd += f" -Location '{location}'"
    
    if excel_output_path:
        cmd += f" -ExcelOutputPath '{excel_output_path}'"
    
    if dry_run:
        cmd += " -DryRun"
    
    return cmd

def generate_remove_command(conference_name, domain, remove_groups, remove_resource_groups, force, dry_run):
    """Generate PowerShell command for removing users."""
    cmd = f".\\Remove-ConferenceUsers.ps1 -ConferenceName '{conference_name}'"
    
    if domain:
        cmd += f" -Domain '{domain}'"
    
    if not remove_groups:
        cmd += " -RemoveGroups $false"
    
    if remove_resource_groups:
        cmd += " -RemoveResourceGroups $true"
    
    if force:
        cmd += " -Force"
    
    if dry_run:
        cmd += " -DryRun"
    
    return cmd

@app.route('/about')
def about():
    """About page with information about the tool."""
    return render_template('about.html')

if __name__ == '__main__':
    # Run the Flask development server
    app.run(debug=True, host='0.0.0.0', port=5000)