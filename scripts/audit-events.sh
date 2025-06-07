#!/bin/bash

# Configuration
LOG_DIR="/var/log/k8s-audit"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/kubelet_events_${TIMESTAMP}.log"

# Create log directory if it doesn't exist
mkdir -p ${LOG_DIR}

# Function to check for critical events
check_critical_events() {
    kubectl get events --field-selector source=kubelet --sort-by='.lastTimestamp' | \
    grep -E "Failed|Error|CrashLoopBackOff|ImagePullBackOff" > "${LOG_FILE}"

    # If there are critical events, send alert
    if [ -s "${LOG_FILE}" ]; then
        echo "Critical events detected at $(date)" >> "${LOG_FILE}"
        # Here you would add your alert mechanism (e.g., Slack, Discord)
        # Example: curl -X POST -H 'Content-type: application/json' --data '{"text":"Critical events detected"}' $SLACK_WEBHOOK_URL
    fi
}

# Main execution
echo "Starting kubelet event audit at $(date)"
check_critical_events
echo "Audit completed at $(date)"

# Cleanup old logs (keep last 7 days)
find ${LOG_DIR} -name "kubelet_events_*.log" -mtime +7 -delete 