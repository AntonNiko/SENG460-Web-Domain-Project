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

# Call dig on the domain name. We accomodate if it's an IP address.
if echo "$DOMAIN_NAME" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > /dev/null; then
    DIG_OUTPUT=$(dig -x $DOMAIN_NAME)
else 
    DIG_OUTPUT=$(dig $DOMAIN_NAME)
fi
echo "Successfully executed dig on $DOMAIN_NAME"

# If we see that no match were found (i.e. no answer), then exit, UNLESS
# the DOMAIN_NAME is an IP address. In that case, we do not expect an answer,
# so continue
if echo "$DIG_OUTPUT" | grep "ANSWER: 0" > /dev/null; then
    echo "Warning: no answer received for dig $DOMAIN_NAME."
fi

###########################################################################
# Below we filter and append the output file with all desired information.
###########################################################################
OUTPUT_FILENAME="output_$DOMAIN_NAME.txt"

# Add header to file
echo -e "# SENG 460 - Spring 2022 \n# Output of lookup of website: $DOMAIN_NAME\n" > $OUTPUT_FILENAME

# Output registrar abuse email
# TODO: Fix formatting and filtering
echo "Email the following registrar email address to report abuse: " >> $OUTPUT_FILENAME
echo "$WHOIS_OUTPUT" | sed -n '/abuse/ Ip' | sed -n '/email/ Ip' | cut -d: -f2 >> $OUTPUT_FILENAME

# Output general registrar information
echo "The website's corresponding registrar information is shown below: " >> $OUTPUT_FILENAME
echo "$WHOIS_OUTPUT" | sed -n '/registrar/ Ip' >> $OUTPUT_FILENAME

# Get DNS hostname information
echo "The query for $DOMAIN_NAME returns the following IP/Domain name: " >> $OUTPUT_FILENAME




exit 0