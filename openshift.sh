#!/bin/bash

# OpenShift Local (CRC) Deployment Script
# This script automates the setup, installation, and configuration of OpenShift Local

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}ERROR:${NC} $1"
    exit 1
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is not installed. Please install it and try again."
    else
        log_success "$1 is installed."
    fi
}

# Check if Docker is running
check_docker_running() {
    log_info "Checking if Docker is running..."
    if docker info &>/dev/null; then
        log_success "Docker is running"
        return 0
    else
        log_warning "Docker is not running or not installed"
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check OS
    OS=$(uname -s)
    case "$OS" in
        "Darwin")
            log_info "Running on macOS"
            check_command brew
            ;;
        "Linux")
            log_info "Running on Linux"
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                log_info "Distribution: $NAME"
            fi
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            ;;
    esac
    
    # Check required tools
    check_command curl
    check_command tar
    
    # Check if Docker is installed and running
    check_command docker
    check_docker_running
    
    # Check if CRC is installed
    if ! command -v crc &> /dev/null; then
        log_warning "OpenShift Local (CRC) is not installed on your system."
        log_info "Please download it from: https://console.redhat.com/openshift/create/local"
        log_info "You'll need to create a Red Hat account and use the CRC pull secret provided there."
        return 1
    else
        log_success "OpenShift Local (CRC) is already installed."
        log_info "Installed version: $(crc version | grep -o 'OpenShift version:.*' | head -1 || crc version | head -1)"
    fi
    
    log_success "Prerequisites check completed"
}

# Install CRC (CodeReady Containers / OpenShift Local)
install_crc() {
    # Check if CRC is already installed
    if command -v crc &> /dev/null; then
        log_info "OpenShift Local (CRC) is already installed."
        log_info "Installed version: $(crc version | grep -o 'OpenShift version:.*' | head -1 || crc version | head -1)"
        log_info "If you want to reinstall or upgrade, please:"
        log_info "1. Download the latest version from: https://console.redhat.com/openshift/create/local"
        log_info "2. Get your pull secret from the same location"
        return 0
    fi
    
    log_info "OpenShift Local (CRC) is not installed."
    log_info "Please download it from: https://console.redhat.com/openshift/create/local"
    log_info "You'll need to:"
    log_info "1. Create a Red Hat account if you don't have one"
    log_info "2. Download the appropriate version for your OS"
    log_info "3. Download your pull secret"
    log_info "4. Extract the archive and move the 'crc' binary to your PATH"
    log_info "5. Save your pull secret to $HOME/.crc/pull-secret.json"
    
    # Ask if user wants guidance on manual installation
    read -p "Would you like instructions for manual installation? (y/n): " show_instructions
    if [[ "$show_instructions" =~ ^[Yy]$ ]]; then
        echo ""
        log_info "Manual Installation Instructions:"
        echo "1. Go to https://console.redhat.com/openshift/create/local"
        echo "2. Download the appropriate version for your OS"
        echo "3. Extract the archive:"
        echo "   tar -xf crc-*-amd64.tar.xz"
        echo "4. Move the binary to your PATH:"
        echo "   sudo cp ./crc-*-amd64/crc /usr/local/bin/"
        echo "   sudo chmod +x /usr/local/bin/crc"
        echo "5. Download your pull secret from the same page"
        echo "6. Create the directory for the pull secret:"
        echo "   mkdir -p $HOME/.crc"
        echo "7. Save your pull secret:"
        echo "   cp path/to/pull-secret.txt $HOME/.crc/pull-secret.json"
        echo ""
    fi
    
    return 0
}

# Setup CRC environment
setup_environment() {
    # Check if CRC is installed before proceeding
    if ! command -v crc &> /dev/null; then
        log_error "OpenShift Local (CRC) is not installed."
        log_info "Please download it from: https://console.redhat.com/openshift/create/local"
        return 1
    fi
    
    # Check for pull secret
    PULL_SECRET_PATH="$HOME/.crc/pull-secret.json"
    if [ ! -f "$PULL_SECRET_PATH" ]; then
        log_warning "Pull secret not found at $PULL_SECRET_PATH"
        log_info "Please download your pull secret from: https://console.redhat.com/openshift/create/local"
        log_info "and save it to $PULL_SECRET_PATH before continuing."
        
        read -p "Do you want to continue without the pull secret? (y/n): " continue_without_secret
        if [[ ! "$continue_without_secret" =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled. Please set up your pull secret and try again."
            return 1
        fi
    fi
    
    log_info "Setting up CRC environment..."
    
    # Load configuration
    CONFIG_FILE="crc-config.json"
    if [ -f "$CONFIG_FILE" ]; then
        log_info "Loading configuration from $CONFIG_FILE"
        # Check if jq is installed first
        if ! command -v jq &> /dev/null; then
            log_warning "jq is not installed. Using default configuration."
            MEMORY="16384"
            CPUS="6" 
            DISK_SIZE="100"
        else
            # Parse memory, cpus, disk size from config file if it exists
            MEMORY=$(jq -r '.memory // "16384"' "$CONFIG_FILE")
            CPUS=$(jq -r '.cpus // "6"' "$CONFIG_FILE")
            DISK_SIZE=$(jq -r '.diskSize // "100"' "$CONFIG_FILE")
        fi
    else
        # Default values
        MEMORY="16384"
        CPUS="6"
        DISK_SIZE="100"
        log_info "Using default configuration: $CPUS CPUs, ${MEMORY}MB RAM, ${DISK_SIZE}GB disk"
    fi
    
    # Setup CRC
    log_info "Setting up CRC with $CPUS CPUs, ${MEMORY}MB RAM, ${DISK_SIZE}GB disk"
    crc setup
    
    # Configure CRC settings
    crc config set memory $MEMORY
    crc config set cpus $CPUS
    crc config set disk-size $DISK_SIZE
    
    # Additional configurations
    crc config set consent-telemetry no
    
    log_success "CRC environment setup completed"
}

# Start CRC
start_crc() {
    # Check if CRC is installed before proceeding
    if ! command -v crc &> /dev/null; then
        log_error "OpenShift Local (CRC) is not installed."
        log_info "Please download it from: https://console.redhat.com/openshift/create/local"
        return 1
    fi
    
    log_info "Starting OpenShift cluster..."
    
    # Check for pull secret
    PULL_SECRET_PATH="$HOME/.crc/pull-secret.json"
    if [ ! -f "$PULL_SECRET_PATH" ]; then
        log_warning "Pull secret not found at $PULL_SECRET_PATH"
        log_info "Please download your pull secret from: https://console.redhat.com/openshift/create/local"
        log_info "and save it to $PULL_SECRET_PATH before starting the cluster."
        
        read -p "Do you want to continue without the pull secret in the default location? (y/n): " continue_without_secret
        if [[ ! "$continue_without_secret" =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled. Please set up your pull secret and try again."
            return 1
        fi
        
        log_info "You will be prompted to enter the path to your pull secret during startup."
    fi
    
    # Interactive mode - ask for configuration options
    read -p "Would you like to start with default configuration? (y/n): " use_default
    
    if [[ "$use_default" =~ ^[Nn]$ ]]; then
        # Ask for memory
        read -p "Enter memory in MB (default: 16384): " custom_memory
        custom_memory=${custom_memory:-16384}
        
        # Ask for CPUs
        read -p "Enter number of CPUs (default: 6): " custom_cpus
        custom_cpus=${custom_cpus:-6}
        
        # Ask for disk size
        read -p "Enter disk size in GB (default: 100): " custom_disk
        custom_disk=${custom_disk:-100}
        
        # Configure CRC settings
        log_info "Applying custom configuration..."
        crc config set memory $custom_memory
        crc config set cpus $custom_cpus
        crc config set disk-size $custom_disk
    fi
    
    # Start CRC
    crc start
    
    if [ $? -eq 0 ]; then
        log_success "OpenShift cluster started successfully"
        
        # Display connection information
        log_info "Getting login credentials..."
        echo ""
        crc console --credentials
        echo ""
        log_info "You can access the OpenShift console by running: crc console"
    else
        log_error "Failed to start OpenShift cluster"
    fi
}

# Stop CRC
stop_crc() {
    # Check if CRC is installed before proceeding
    if ! command -v crc &> /dev/null; then
        log_error "OpenShift Local (CRC) is not installed. Please install it first."
    fi
    
    log_info "Stopping OpenShift cluster..."
    
    # Ask for confirmation
    read -p "Are you sure you want to stop the OpenShift cluster? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        crc stop
        if [ $? -eq 0 ]; then
            log_success "OpenShift cluster stopped successfully"
        else
            log_error "Failed to stop OpenShift cluster"
        fi
    else
        log_info "Operation cancelled"
    fi
}

# Status of CRC
status_crc() {
    # Check if CRC is installed before proceeding
    if ! command -v crc &> /dev/null; then
        log_error "OpenShift Local (CRC) is not installed. Please install it first."
    fi
    
    log_info "Checking OpenShift cluster status..."
    crc status
}

# Interactive menu
show_menu() {
    clear
    echo "========================================================"
    echo "  OpenShift Local (CRC) Management Script"
    echo "========================================================"
    echo ""
    echo "  1) Check prerequisites"
    echo "  2) Get download & installation instructions"
    echo "  3) Setup environment"
    echo "  4) Start OpenShift cluster"
    echo "  5) Show cluster status"
    echo "  6) Open web console"
    echo "  7) Show cluster info"
    echo "  8) Stop OpenShift cluster"
    echo "  9) Exit"
    echo ""
    echo "========================================================"
    
    read -p "Please select an option [1-9]: " menu_option
    
    case $menu_option in
        1)
            check_prerequisites
            ;;
        2)
            install_crc
            ;;
        3)
            setup_environment
            ;;
        4)
            start_crc
            ;;
        5)
            status_crc
            ;;
        6)
            if command -v crc &> /dev/null; then
                log_info "Opening web console..."
                crc console
            else
                log_error "CRC is not installed"
            fi
            ;;
        7)
            if command -v crc &> /dev/null; then
                log_info "Cluster information:"
                echo ""
                crc console --credentials
                echo ""
            else
                log_error "CRC is not installed"
            fi
            ;;
        8)
            stop_crc
            ;;
        9)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid option. Please try again."
            ;;
    esac
    
    # Pause before showing the menu again
    read -p "Press Enter to continue..."
    show_menu
}

# Main function
main() {
    echo "========================================================"
    echo "  OpenShift Local (CRC) Deployment Script"
    echo "========================================================"
    echo ""
    
    # Process command line arguments
    ACTION=${1:-"interactive"}
    
    case "$ACTION" in
        "check")
            check_prerequisites
            ;;
        "install")
            check_prerequisites
            install_crc $2
            ;;
        "setup")
            setup_environment
            ;;
        "start")
            start_crc
            ;;
        "stop")
            stop_crc
            ;;
        "status")
            status_crc
            ;;
        "interactive")
            show_menu
            ;;
        "all")
            check_prerequisites
            install_crc
            setup_environment
            start_crc
            ;;
        "help")
            echo "Usage: $0 [action] [options]"
            echo ""
            echo "Actions:"
            echo "  check       - Check system prerequisites"
            echo "  install     - Install CRC (optionally specify version)"
            echo "  setup       - Setup CRC environment"
            echo "  start       - Start OpenShift cluster"
            echo "  stop        - Stop OpenShift cluster"
            echo "  status      - Show cluster status"
            echo "  interactive - Show interactive menu (default)"
            echo "  all         - Perform check, install, setup, start"
            echo "  help        - Display this help message"
            echo ""
            echo "Examples:"
            echo "  $0                         # Run in interactive mode"
            echo "  $0 check                   # Check prerequisites"
            echo "  $0 install latest          # Install latest CRC version"
            echo "  $0 install 1.38.0          # Install specific CRC version"
            echo "  $0 start                   # Start OpenShift cluster"
            ;;
        *)
            log_error "Unknown action: $ACTION. Use '$0 help' for usage information."
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
