#!/bin/bash
###############################################################################
# Script: update-trivy-db.sh
# Descrição: Atualiza o banco de dados de vulnerabilidades do Trivy
# Uso: ./update-trivy-db.sh
# Cron: 0 2 * * 0 (Domingos às 2h da manhã)
###############################################################################

set -euo pipefail

# ========================================
# CONFIGURAÇÕES
# ========================================
TRIVY_CACHE_DIR="/home/jenkins/trivy_cache"
LOG_DIR="/var/log/trivy"
LOG_FILE="${LOG_DIR}/trivy-db-update.log"
LOCK_FILE="/var/run/trivy-update.lock"
RETENTION_DAYS=30

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ========================================
# FUNÇÕES
# ========================================

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    log "INFO" "${GREEN}$@${NC}"
}

log_warn() {
    log "WARN" "${YELLOW}$@${NC}"
}

log_error() {
    log "ERROR" "${RED}$@${NC}"
}

check_lock() {
    if [ -f "${LOCK_FILE}" ]; then
        local pid=$(cat "${LOCK_FILE}")
        if ps -p "${pid}" > /dev/null 2>&1; then
            log_warn "Another update is running (PID: ${pid}). Exiting."
            exit 0
        else
            log_warn "Stale lock file found. Removing."
            rm -f "${LOCK_FILE}"
        fi
    fi
}

create_lock() {
    echo $$ > "${LOCK_FILE}"
}

remove_lock() {
    rm -f "${LOCK_FILE}"
}

check_network() {
    log_info "Checking network connectivity..."
    
    local urls=(
        "https://github.com"
        "https://api.github.com"
        "https://objects.githubusercontent.com"
    )
    
    for url in "${urls[@]}"; do
        if ! curl -s --connect-timeout 10 --max-time 30 -o /dev/null "${url}"; then
            log_error "Cannot reach ${url}. Check firewall rules."
            return 1
        fi
    done
    
    log_info "Network connectivity OK"
    return 0
}

get_current_db_info() {
    if [ -d "${TRIVY_CACHE_DIR}/db" ]; then
        local db_metadata="${TRIVY_CACHE_DIR}/db/metadata.json"
        if [ -f "${db_metadata}" ]; then
            local version=$(jq -r '.Version' "${db_metadata}" 2>/dev/null || echo "unknown")
            local updated=$(jq -r '.UpdatedAt' "${db_metadata}" 2>/dev/null || echo "unknown")
            log_info "Current DB Version: ${version} (Updated: ${updated})"
        else
            log_warn "DB exists but no metadata found"
        fi
    else
        log_info "No existing Trivy DB found"
    fi
}

update_db() {
    log_info "Starting Trivy database update..."
    log_info "Cache directory: ${TRIVY_CACHE_DIR}"
    
    # Ensure cache directory exists and has correct permissions
    mkdir -p "${TRIVY_CACHE_DIR}"
    chown -R jenkins:jenkins "${TRIVY_CACHE_DIR}"
    
    # Get current DB info before update
    get_current_db_info
    
    # Download/update database with timeout
    log_info "Downloading vulnerability database..."
    local start_time=$(date +%s)
    
    if timeout 600 trivy image --download-db-only --cache-dir "${TRIVY_CACHE_DIR}" 2>&1 | tee -a "${LOG_FILE}"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_info "Database updated successfully in ${duration} seconds"
        
        # Get new DB info
        get_current_db_info
        
        # Verify database integrity
        if [ -d "${TRIVY_CACHE_DIR}/db" ] && [ -f "${TRIVY_CACHE_DIR}/db/metadata.json" ]; then
            local db_size=$(du -sh "${TRIVY_CACHE_DIR}/db" | cut -f1)
            log_info "Database size: ${db_size}"
            return 0
        else
            log_error "Database update completed but files are missing"
            return 1
        fi
    else
        log_error "Database update failed or timed out after 10 minutes"
        return 1
    fi
}

cleanup_old_logs() {
    log_info "Cleaning up logs older than ${RETENTION_DAYS} days..."
    find "${LOG_DIR}" -name "trivy-db-update.log.*" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
    log_info "Log cleanup completed"
}

rotate_log() {
    if [ -f "${LOG_FILE}" ]; then
        local log_size=$(stat -f%z "${LOG_FILE}" 2>/dev/null || stat -c%s "${LOG_FILE}" 2>/dev/null)
        # Rotate if > 10MB
        if [ "${log_size}" -gt 10485760 ]; then
            local timestamp=$(date '+%Y%m%d-%H%M%S')
            mv "${LOG_FILE}" "${LOG_FILE}.${timestamp}"
            log_info "Log file rotated"
        fi
    fi
}

send_notification() {
    local status=$1
    local message=$2
    
    # Phase 2: Integração com Teams/Email
    # sendTeamsNotification(
    #     webhook: "TEAMS_WEBHOOK_URL",
    #     status: "${status}",
    #     message: "Trivy DB Update: ${message}"
    # )
    
    log_info "Notification would be sent: [${status}] ${message}"
}

# ========================================
# MAIN
# ========================================

main() {
    # Ensure log directory exists
    mkdir -p "${LOG_DIR}"
    
    # Rotate log if needed
    rotate_log
    
    log_info "=========================================="
    log_info "Trivy Database Update Started"
    log_info "=========================================="
    log_info "Hostname: $(hostname)"
    log_info "User: $(whoami)"
    log_info "Date: $(date)"
    
    # Check if another update is running
    check_lock
    
    # Create lock file
    create_lock
    
    # Trap to ensure lock is removed on exit
    trap remove_lock EXIT INT TERM
    
    # Check network connectivity
    if ! check_network; then
        log_error "Network connectivity check failed"
        send_notification "ERROR" "Network connectivity failed"
        exit 1
    fi
    
    # Perform database update
    if update_db; then
        log_info "=========================================="
        log_info "Trivy Database Update Completed Successfully"
        log_info "=========================================="
        send_notification "SUCCESS" "Database updated successfully"
        
        # Cleanup old logs
        cleanup_old_logs
        
        exit 0
    else
        log_error "=========================================="
        log_error "Trivy Database Update Failed"
        log_error "=========================================="
        send_notification "FAILURE" "Database update failed"
        exit 1
    fi
}

# Execute main function
main "$@"
