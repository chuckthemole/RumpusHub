#!/bin/bash

# -----------------------------------------------------------------------------
# gcp-instance.sh
#
# Purpose:
#   - Manage a Google Cloud Compute Engine (GCE) instance via gcloud CLI.
#   - Supports SSH access, start, stop, restart, and status commands.
#
# Usage:
#   ./gcp-instance.sh <INSTANCE_NAME> <ZONE> {ssh|start|stop|restart|status|--help}
#
# Example:
#   ./gcp-instance.sh rumpus-room us-west1-a ssh      # SSH into instance
#   ./gcp-instance.sh rumpus-room us-west1-a start    # Start instance
# -----------------------------------------------------------------------------

show_help() {
    echo "Usage: $0 <INSTANCE_NAME> <ZONE> {ssh|start|stop|restart|status|--help}"
    echo ""
    echo "Manage your Google Cloud Compute Engine instance with the following commands:"
    echo "  ssh       - Connect to the instance via SSH"
    echo "  start     - Start the instance if it's stopped"
    echo "  stop      - Stop the instance to save costs"
    echo "  restart   - Restart the instance"
    echo "  status    - Check the instance status"
    echo "  --help    - Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 rumpus-room us-west1-a ssh      # SSH into the instance"
    echo "  $0 rumpus-room us-west1-a start    # Start the instance"
}

# -----------------------------------------------------------------------------
# Validate input
# -----------------------------------------------------------------------------
if [ "$#" -lt 3 ] || [ "$3" == "--help" ]; then
    show_help
    exit 0
fi

INSTANCE_NAME=$1   # GCE instance name
ZONE=$2            # GCE instance zone
COMMAND=$3         # Action: ssh, start, stop, restart, status

# -----------------------------------------------------------------------------
# Execute the requested action
# -----------------------------------------------------------------------------
case "$COMMAND" in
    ssh)
        echo "Connecting to instance '$INSTANCE_NAME' in zone '$ZONE'..."
        gcloud compute ssh --zone="$ZONE" "$INSTANCE_NAME"
        ;;
    start)
        echo "Starting instance '$INSTANCE_NAME' in zone '$ZONE'..."
        gcloud compute instances start "$INSTANCE_NAME" --zone="$ZONE"
        ;;
    stop)
        echo "Stopping instance '$INSTANCE_NAME' in zone '$ZONE'..."
        gcloud compute instances stop "$INSTANCE_NAME" --zone="$ZONE"
        ;;
    restart)
        echo "Restarting instance '$INSTANCE_NAME' in zone '$ZONE'..."
        gcloud compute instances reset "$INSTANCE_NAME" --zone="$ZONE"
        ;;
    status)
        echo "Fetching status of instance '$INSTANCE_NAME' in zone '$ZONE'..."
        gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --format="get(status)"
        ;;
    *)
        echo "Invalid command: $COMMAND"
        show_help
        exit 1
        ;;
esac

# -----------------------------------------------------------------------------
# End of Script
# -----------------------------------------------------------------------------
