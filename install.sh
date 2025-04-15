#!/bin/bash

# Determine the OS and delegate to the appropriate script
case "$(uname -s)" in
    "Linux")
        echo "Detected Linux. Running linux/install.sh..."
        bash ./linux/install.sh
        ;;
    "Darwin")
        echo "Detected macOS. Running mac/install.sh..."
        bash ./mac/install.sh
        ;;
    *)
        echo "Unsupported OS. Exiting."
        exit 1
        ;;
esac
