#!/bin/bash

# Start counter of the amount of records removed
declare -i count=0

# Here we insert the file with the FQDNs we would like to delete
file="fqdns.txt"

while IFS= read -r fqdn
do
  # Error handling incase something is empty.
  if [ -z "$fqdn" ]; then
    echo "Skipping empty line."
    continue
  fi

  # Incase we don't have the IPs we do an nslookup
  ip=$(nslookup $fqdn | grep 'Address: ' | tail -n1 | awk '{print $2}')

  # Check if ip is empty, it means that the records doesn't exist. So we skip it!
  if [ -z "$ip" ]; then
    echo "No IP found for FQDN: $fqdn. Skipping."
    continue
  fi

# We delete the records via AWS CLI
# Note that in our case the Type and TTL is static. So we put A and 90. It might be different for you.
  aws route53 change-resource-record-sets --hosted-zone-id YOUR_HOSTED_ZONE_ID --change-batch '{
    "Changes": [
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "'$fqdn'",
          "Type": "A",
          "TTL": 90,
          "ResourceRecords": [
            {
              "Value": "'$ip'"
            }
          ]
        }
      }
    ]
  }'
  
  echo "Deleted FQDN: $fqdn"
  
  # adding 1 to the total
  ((count++))
  
done < "$file"

# total records deleted
echo "Total deleted records: $count"
