# ==============================================================================
# TEST ENVIRONMENT CONFIGURATION
# ==============================================================================
environment  = "tst"
project_name = "myapp"
location     = "brazilsouth"

# ==============================================================================
# COMPUTE - LINUX VM CREDENTIALS
# ==============================================================================
# IMPORTANTE: Substitua pela sua chave SSH pública
admin_ssh_key_linux = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... user@example.com"

# ==============================================================================
# COMPUTE - WINDOWS VM CREDENTIALS
# ==============================================================================
# IMPORTANTE: Substitua por uma senha segura (mínimo 12 caracteres)
# Armazene em Azure Key Vault ou Jenkins Credentials em produção
admin_password_windows = "ChangeMe123!@#Secure"

