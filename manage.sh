#!/bin/bash

# Barbican Development Environment Management Script

set -e

COMPOSE_FILE="podman-compose.yml"

function print_usage() {
    echo "Usage: $0 {start|stop|restart|status|logs|clean}"
    echo ""
    echo "Commands:"
    echo "  start   - Start all services"
    echo "  stop    - Stop all services"
    echo "  restart - Restart all services"
    echo "  status  - Show service status"
    echo "  logs    - Show logs for all services"
    echo "  clean   - Stop and remove all containers and volumes"
    echo ""
}

function check_podman_compose() {
    if ! command -v podman-compose &> /dev/null; then
        echo "Error: podman-compose is not installed or not in PATH"
        echo "Please install podman-compose to use this script"
        exit 1
    fi
}

function start_services() {
    echo "Starting Barbican development environment..."
    check_podman_compose
    podman-compose -f "$COMPOSE_FILE" up -d
    echo "Services started. Use '$0 status' to check service status."
    echo ""
    echo "Services will be available at:"
    echo "  PostgreSQL: localhost:5432"
    echo "  Memcached:  localhost:11211"
    echo "  Keystone:   http://localhost:5000/v3 (public API)"
    echo "              http://localhost:35357/v3 (admin API)"
}

function stop_services() {
    echo "Stopping Barbican development environment..."
    check_podman_compose
    podman-compose -f "$COMPOSE_FILE" down
    echo "Services stopped."
}

function restart_services() {
    echo "Restarting Barbican development environment..."
    stop_services
    start_services
}

function show_status() {
    echo "Service Status:"
    check_podman_compose
    podman-compose -f "$COMPOSE_FILE" ps
}

function show_logs() {
    echo "Service Logs:"
    check_podman_compose
    podman-compose -f "$COMPOSE_FILE" logs -f
}

function clean_environment() {
    echo "Cleaning up Barbican development environment..."
    echo "This will remove all containers and volumes. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        check_podman_compose
        podman-compose -f "$COMPOSE_FILE" down -v
        echo "Environment cleaned."
    else
        echo "Clean operation cancelled."
    fi
}

# Main command processing
case "${1:-}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    clean)
        clean_environment
        ;;
    *)
        print_usage
        exit 1
        ;;
esac