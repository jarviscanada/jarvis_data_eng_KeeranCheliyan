#!/bin/bash

# Setup and validate arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Check # of args
if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    echo "Usage: ./host_info.sh psql_host psql_port db_name psql_user psql_password"
    exit 1
fi

# Save machine statistics in MB and current machine hostname to variables 
vmstat_mb=$(vmstat --unit M)
hostname=$(hostname -f)
lscpu_out=$(lscpu)

#Retrieve hardware specification variables
cpu_number=$(echo "$lscpu_out" | grep -E "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out" | grep -E "^Architecture:" | awk '{print $2}' | xargs)
cpu_model=$(echo "$lscpu_out" | grep -E "^Model name:" | cut -d':' -f2 | xargs)
cpu_mhz=$(echo "$lscpu_out" | grep -E "^BogoMIPS:" | awk '{print $2 / 2}' | xargs)
l2_cache=$(echo "$lscpu_out" | grep -E "^L2 cache:" | awk '{print $3}' | xargs)
total_mem=$(grep -E "^MemTotal:" /proc/meminfo | awk '{print int($2/1024)}')
timestamp=$(vmstat -t | awk '{print $18, $19}' | tail -n1 | xargs)

# Insert Statement
insert_stmt="INSERT INTO host_info(hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, total_mem, \"timestamp\") VALUES('$hostname', $cpu_number, '$cpu_architecture', '$cpu_model', $cpu_mhz, $l2_cache, $total_mem, '$timestamp');"

# Set up env var for psql password and execute INSERT
export PGPASSWORD=$psql_password
psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$insert_stmt"

exit $?
