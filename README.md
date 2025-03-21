# OpenShift Local Deployment Manager

This project provides a script to manage OpenShift Local (formerly CodeReady Containers/CRC) on your local machine.

## Overview

The `openshift.sh` script offers an interactive way to:
- Check system prerequisites
- Get installation instructions for OpenShift Local
- Configure and manage your OpenShift Local environment
- Start and stop your OpenShift cluster
- Access the web console and cluster information

## Prerequisites

- macOS or Linux operating system
- Docker installed and running
- curl and tar utilities
- Internet connection
- 16GB RAM minimum (recommended)
- 35GB+ of free disk space
- A Red Hat account (free to create)
- OpenShift Local pull secret from Red Hat

## Installation

1. Make sure you have downloaded OpenShift Local from the [Red Hat Console](https://console.redhat.com/openshift/create/local)

2. Make the script executable:
   ```
   chmod +x openshift.sh
   ```

3. Run the script in interactive mode:
   ```
   ./openshift.sh
   ```

## Usage Options

### Interactive Mode

Simply run the script to enter interactive mode:
```
./openshift.sh
```

This will present a menu with the following options:
1. Check prerequisites
2. Get download & installation instructions
3. Setup environment
4. Start OpenShift cluster
5. Show cluster status
6. Open web console
7. Show cluster info
8. Stop OpenShift cluster
9. Exit

### Command Line Mode

The script also accepts commands for non-interactive use:

```
./openshift.sh [action] [options]
```

Available actions:
- `check`: Check system prerequisites
- `install`: Get installation instructions
- `setup`: Setup CRC environment
- `start`: Start OpenShift cluster
- `stop`: Stop OpenShift cluster
- `status`: Show cluster status
- `interactive`: Show interactive menu (default)
- `all`: Perform check, install, setup, start
- `help`: Display help message

Examples:
```
./openshift.sh check                   # Check prerequisites
./openshift.sh start                   # Start OpenShift cluster
```

## Getting the Pull Secret

The script requires a pull secret from Red Hat:

1. Go to [Red Hat Console](https://console.redhat.com/openshift/create/local)
2. Log in with your Red Hat account
3. Download your pull secret
4. Save it to `$HOME/.crc/pull-secret.json`

## Configuration

The script can use a configuration file named `crc-config.json` in the same directory. Example:

```json
{
  "memory": "16384",
  "cpus": "6",
  "diskSize": "100"
}
```

Without this file, default values will be used.

## Troubleshooting

- Ensure Docker is installed and running
- Ensure your machine meets the minimum hardware requirements
- Verify that your pull secret is correctly saved at `$HOME/.crc/pull-secret.json`
- Check virtualization is enabled in your BIOS
- For macOS users, ensure Hyperkit or Docker Machine driver is installed
- For Linux users, ensure libvirt is installed and properly configured

## License

This project is licensed under the MIT License - see the LICENSE file for details.
