// JavaScript functionality for Conference User Creation Web Frontend

document.addEventListener('DOMContentLoaded', function() {
    // Initialize tooltips (if Bootstrap tooltips are used)
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Form validation enhancement
    enhanceFormValidation();
    
    // Auto-hide alerts
    autoHideAlerts();
    
    // Add smooth scrolling
    addSmoothScrolling();
});

/**
 * Enhance form validation with real-time feedback
 */
function enhanceFormValidation() {
    const forms = document.querySelectorAll('form');
    
    forms.forEach(function(form) {
        // Conference name validation
        const conferenceNameInput = form.querySelector('#conference_name');
        if (conferenceNameInput) {
            conferenceNameInput.addEventListener('input', function() {
                validateConferenceName(this);
            });
        }
        
        // User count validation
        const userCountInput = form.querySelector('#user_count');
        if (userCountInput) {
            userCountInput.addEventListener('input', function() {
                validateUserCount(this);
            });
        }
        
        // Domain validation
        const domainInput = form.querySelector('#domain');
        if (domainInput) {
            domainInput.addEventListener('input', function() {
                validateDomain(this);
            });
        }
        
        // Subscription ID validation
        const subscriptionIdInput = form.querySelector('#subscription_id');
        if (subscriptionIdInput) {
            subscriptionIdInput.addEventListener('input', function() {
                validateSubscriptionId(this);
            });
        }
    });
}

/**
 * Validate conference name format
 */
function validateConferenceName(input) {
    const value = input.value.trim();
    const pattern = /^[a-zA-Z0-9_-]+$/;
    
    if (value && !pattern.test(value)) {
        setInputError(input, 'Conference name must contain only letters, numbers, hyphens, and underscores');
    } else {
        clearInputError(input);
    }
}

/**
 * Validate user count range
 */
function validateUserCount(input) {
    const value = parseInt(input.value);
    
    if (value && (value < 1 || value > 1000)) {
        setInputError(input, 'User count must be between 1 and 1000');
    } else {
        clearInputError(input);
    }
}

/**
 * Validate domain format
 */
function validateDomain(input) {
    const value = input.value.trim();
    const pattern = /^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    
    if (value && !pattern.test(value)) {
        setInputError(input, 'Please enter a valid domain name (e.g., company.com)');
    } else {
        clearInputError(input);
    }
}

/**
 * Validate subscription ID format
 */
function validateSubscriptionId(input) {
    const value = input.value.trim();
    const pattern = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
    
    if (value && !pattern.test(value)) {
        setInputError(input, 'Please enter a valid GUID format (e.g., 12345678-1234-1234-1234-123456789012)');
    } else {
        clearInputError(input);
    }
}

/**
 * Set input error state
 */
function setInputError(input, message) {
    input.classList.add('is-invalid');
    
    // Remove existing error message
    const existingError = input.parentNode.querySelector('.invalid-feedback');
    if (existingError) {
        existingError.remove();
    }
    
    // Add new error message
    const errorDiv = document.createElement('div');
    errorDiv.className = 'invalid-feedback';
    errorDiv.textContent = message;
    input.parentNode.appendChild(errorDiv);
}

/**
 * Clear input error state
 */
function clearInputError(input) {
    input.classList.remove('is-invalid');
    
    const errorDiv = input.parentNode.querySelector('.invalid-feedback');
    if (errorDiv) {
        errorDiv.remove();
    }
}

/**
 * Auto-hide alerts after a delay
 */
function autoHideAlerts() {
    const alerts = document.querySelectorAll('.alert:not(.alert-warning):not(.alert-danger)');
    
    alerts.forEach(function(alert) {
        // Don't auto-hide error or warning alerts
        if (!alert.classList.contains('alert-danger') && !alert.classList.contains('alert-warning')) {
            setTimeout(function() {
                if (alert && alert.parentNode) {
                    alert.style.transition = 'opacity 0.5s ease-out';
                    alert.style.opacity = '0';
                    setTimeout(function() {
                        if (alert && alert.parentNode) {
                            alert.remove();
                        }
                    }, 500);
                }
            }, 5000);
        }
    });
}

/**
 * Add smooth scrolling for anchor links
 */
function addSmoothScrolling() {
    const links = document.querySelectorAll('a[href^="#"]');
    
    links.forEach(function(link) {
        link.addEventListener('click', function(e) {
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                e.preventDefault();
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

/**
 * Toggle resource group options visibility
 */
function toggleResourceGroupOptions() {
    const checkbox = document.getElementById('create_resource_groups');
    const options = document.getElementById('resourceGroupOptions');
    
    if (checkbox && options) {
        options.style.display = checkbox.checked ? 'block' : 'none';
        
        // Add animation
        if (checkbox.checked) {
            options.style.opacity = '0';
            options.style.transform = 'translateY(-10px)';
            setTimeout(function() {
                options.style.transition = 'all 0.3s ease-in-out';
                options.style.opacity = '1';
                options.style.transform = 'translateY(0)';
            }, 10);
        }
    }
}

/**
 * Copy command to clipboard with enhanced feedback
 */
function copyCommand() {
    const commandText = document.getElementById('commandText');
    if (!commandText) return;
    
    const text = commandText.textContent || commandText.innerText;
    
    // Use modern clipboard API if available
    if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(text).then(function() {
            showCopySuccess();
        }).catch(function(err) {
            fallbackCopyTextToClipboard(text);
        });
    } else {
        fallbackCopyTextToClipboard(text);
    }
}

/**
 * Fallback copy method for older browsers
 */
function fallbackCopyTextToClipboard(text) {
    const textArea = document.createElement("textarea");
    textArea.value = text;
    textArea.style.position = "fixed";
    textArea.style.left = "-999999px";
    textArea.style.top = "-999999px";
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    
    try {
        document.execCommand('copy');
        showCopySuccess();
    } catch (err) {
        showCopyError();
    }
    
    document.body.removeChild(textArea);
}

/**
 * Show copy success feedback
 */
function showCopySuccess() {
    const button = event.target.closest('button');
    if (!button) return;
    
    const originalHTML = button.innerHTML;
    const originalClasses = button.className;
    
    button.innerHTML = '<i class="bi bi-check"></i> Copied!';
    button.className = button.className.replace('btn-outline-primary', 'btn-success');
    button.classList.add('copied');
    
    setTimeout(function() {
        button.innerHTML = originalHTML;
        button.className = originalClasses;
        button.classList.remove('copied');
    }, 2000);
}

/**
 * Show copy error feedback
 */
function showCopyError() {
    // Create a temporary alert
    const alertDiv = document.createElement('div');
    alertDiv.className = 'alert alert-warning alert-dismissible fade show mt-3';
    alertDiv.innerHTML = `
        <strong>Copy failed!</strong> Please select and copy the command manually.
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    const commandCard = document.querySelector('#commandText').closest('.card');
    commandCard.parentNode.insertBefore(alertDiv, commandCard);
    
    // Auto-hide after 5 seconds
    setTimeout(function() {
        if (alertDiv && alertDiv.parentNode) {
            alertDiv.remove();
        }
    }, 5000);
}

/**
 * Form submission enhancement
 */
function enhanceFormSubmission() {
    const forms = document.querySelectorAll('form');
    
    forms.forEach(function(form) {
        form.addEventListener('submit', function(e) {
            const submitButton = form.querySelector('button[type="submit"]');
            if (submitButton) {
                const originalText = submitButton.innerHTML;
                submitButton.innerHTML = '<i class="bi bi-hourglass-split"></i> Generating...';
                submitButton.disabled = true;
                
                // Re-enable if form validation fails
                setTimeout(function() {
                    if (form.checkValidity && !form.checkValidity()) {
                        submitButton.innerHTML = originalText;
                        submitButton.disabled = false;
                    }
                }, 100);
            }
        });
    });
}

// Initialize form submission enhancement when DOM is loaded
document.addEventListener('DOMContentLoaded', enhanceFormSubmission);