#!/bin/bash
# This script must be run with sudo privileges to install required dependencies.
# e.g.: sudo ./script.sh uvic.ca

# Check that domain name / IP address argument provided.
if [[ "$1" == "" || $# -lt 1 ]]; then
    echo "Domain name / IP address argument not provided."
    exit 0
fi

# Ensure required apt packages are installed
if ! which whois > /dev/null; then
    echo "whois command not found. Installing..."
    apt-get install whois
fi

ADDRESS=$1

# Call whois on the domain name
WHOIS_OUTPUT=$(whois $ADDRESS)
# If we see that no match were found, then exit.
if echo "$WHOIS_OUTPUT" | grep "No match for domain" > /dev/null; then
    echo "No match for whois $ADDRESS found."
    exit 0
fi
echo "Successfully executed whois on $ADDRESS"

# Call dig on the address. We accomodate if it's an IP address.
if echo "$ADDRESS" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > /dev/null; then
    IS_IP_ADDRESS=1
    DIG_OUTPUT=$(dig -x $ADDRESS)
    DIG_ANSWER_OUTPUT=$(dig +noall +answer -x $ADDRESS)
else 
    IS_IP_ADDRESS=0
    DIG_OUTPUT=$(dig $ADDRESS)
    DIG_ANSWER_OUTPUT=$(dig +noall +answer $ADDRESS)
    DIG_NS_OUTPUT=$(dig ns +noall +answer $ADDRESS)
fi
echo "Successfully executed dig on $ADDRESS"

# If we see that no match were found (i.e. no answer), then exit, UNLESS
# the ADDRESS is an IP address. In that case, we do not expect an answer,
# so continue
if echo "$DIG_OUTPUT" | grep "ANSWER: 0" > /dev/null; then
    echo "Warning: no answer received for dig $ADDRESS."
fi

###########################################################################
# Below we filter and append the output file with all desired information.
###########################################################################
OUTPUT_FILENAME="output_$ADDRESS.txt"

# Add header to file
echo -e "# SENG 460 - Spring 2022 \n# Output of lookup for address: $ADDRESS\n" > $OUTPUT_FILENAME

# Output registrar abuse email
# TODO: Fix formatting and filtering
echo "Email the following registrar email address to report abuse: " >> $OUTPUT_FILENAME
echo "$WHOIS_OUTPUT" | sed -n '/abuse/ Ip' | sed -n '/email/ Ip' | cut -d: -f2 >> $OUTPUT_FILENAME

# Output general registrar information
echo "The website's corresponding registrar information is shown below: " >> $OUTPUT_FILENAME
echo "$WHOIS_OUTPUT" | sed -n '/Registrar URL/ Ip' >> $OUTPUT_FILENAME
echo "$WHOIS_OUTPUT" | sed -n '/Registrar:/ Ip' >> $OUTPUT_FILENAME
echo "$WHOIS_OUTPUT" | sed -n '/Registry Domain ID:/ Ip' >> $OUTPUT_FILENAME
#echo "$WHOIS_OUTPUT" | sed -n '/registrar/ Ip' >> $OUTPUT_FILENAME

# Get DNS hostname information
if [[ "$IS_IP_ADDRESS" -eq "1" ]]; then
    echo -e "\n\nThe query for $ADDRESS returns the following Domain name(s): " >> $OUTPUT_FILENAME
    echo "$DIG_ANSWER_OUTPUT" | cut -d$'\t' -f3 >> $OUTPUT_FILENAME
else
    echo -e "\n\nThe query for $ADDRESS returns the following IP address(es): " >> $OUTPUT_FILENAME
    echo "$DIG_ANSWER_OUTPUT" | cut -d$'\t' -f6 >> $OUTPUT_FILENAME
fi

# If we input domain name, then output the DNS servers of that domain.
if [[ "$IS_IP_ADDRESS" -eq "0" ]]; then
    echo -e "\nDNS Servers for address $ADDRESS:" >> $OUTPUT_FILENAME
    echo "$DIG_NS_OUTPUT" | cut -d$'\t' -f6 >> $OUTPUT_FILENAME
fi

# Must provide: Domain Registrar, Web hosting provided, DNS hosting provider, network provider.

echo "Results of ping operation on address:" >> $OUTPUT_FILENAME
# Ping the destination 4 times to determine average RTT
PING_OUTPUT=$(ping -c 4 $ADDRESS)

# Extract results and append relevant information to file, such as minimum, maximum, and average RTT.
PING_STATS=$(echo "$PING_OUTPUT" | sed -n '/rtt/ p')
echo "Minimum RTT (ms)" >> $OUTPUT_FILENAME
echo $PING_STATS | cut -d/ -f4 | cut -d= -f2 >> $OUTPUT_FILENAME
echo "Maximum RTT (ms)" >> $OUTPUT_FILENAME
echo $PING_STATS | cut -d/ -f5 >> $OUTPUT_FILENAME
echo "Average RTT (ms)" >> $OUTPUT_FILENAME
echo $PING_STATS | cut -d/ -f6 >> $OUTPUT_FILENAME

exit 0