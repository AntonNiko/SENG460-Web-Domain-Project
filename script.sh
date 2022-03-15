#!/bin/bash
# This script must be run with sudo privileges to install required dependencies.
# e.g.: sudo ./script.sh uvic.ca

# Check that domain name / IP address argument provided.
if [[ "$1" == "" || $# -lt 1 ]]; then
    echo "Domain name / IP address parameter not provided."
    exit 0
fi

# Ensure required apt packages are installed
if ! which whois > /dev/null; then
    echo "whois command not found. Installing..."
    apt-get install whois
fi

DOMAIN_NAME=$1

# Call whois on the domain name
WHOIS_OUTPUT=$(whois $DOMAIN_NAME)
# If we see that no match were found, then exit.
if echo "$WHOIS_OUTPUT" | grep "No match for domain" > /dev/null; then
    echo "No match for whois $DOMAIN_NAME found."
    exit 0
fi
echo "Successfully executed whois on $DOMAIN_NAME"

# Call dig on the domain name
DIG_OUTPUT=$(dig $DOMAIN_NAME)
# If we see that no match were found (i.e. no answer), then exit, UNLESS
# the DOMAIN_NAME is an IP address. In that case, we do not expect an answer,
# so continue
if echo "$DIG_OUTPUT" | grep "ANSWER: 0" > /dev/null; then
    echo "No answer received for dig $DOMAIN_NAME."

    if ! echo "$DOMAIN_NAME" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > /dev/null; then
        echo "Since provided name is not an IP address, exiting."
        exit 0
    fi
    echo "Domain name is an IP address, so continue."
fi
echo "Successfully executed dig on $DOMAIN_NAME"


##################################################################
# Below we filter and build the file with all desired information.
##################################################################

exit 0