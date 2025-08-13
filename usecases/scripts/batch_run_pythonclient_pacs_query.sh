#!/bin/bash

success_count=0
total_runs=100
batch_size=1
error_log="errors.log"
time_log="times.log"
times=()

# Clear previous logs
> "$error_log"
> "$time_log"

run_command() {
  start_time=$(date +%s.%N)
  uuid=$(uuidgen); \
  title="query_${uuid}_$1"; \
  output=$(python chris_client_pacs_query.py \
    --username chris \
    --password chris1234 \
    --title "$title" \
    --query "{\"PatientID\" : \"<MRN>\"}" \
    --base-url http://localhost:8000/api/v1 \
    --pacs-name MINICHRISORTHANC \
    --timeout 30 2>&1)
    
  end_time=$(date +%s.%N)
  duration=$(echo "$end_time - $start_time" | bc)
  echo "$duration" >> "$time_log"   

  echo "$output" | grep -qi "success"
  if [[ $? -eq 0 ]]; then
    echo 1
  else
    echo 0
    echo -e "\n---- ERROR in run: $title ----\n$output" >> "$error_log"
  fi
}

# Run loop
for ((i = 1; i <= total_runs; i += batch_size)); do
  echo "Starting batch $((i / batch_size + 1))..."

  for ((j = 0; j < batch_size && i + j <= total_runs; j++)); do
    run_command $((i + j)) &
  done

  wait
done | awk '{s+=$1} END {print "Total successes:", s}'

# Statistics calculation
awk '
  {
    n++
    sum += $1
    sumsq += ($1)^2
  }
  END {
    mean = sum / n
    stddev = sqrt((sumsq - sum^2 / n) / n)
    print "Total time:", sum, "seconds"
    print "Mean time per run:", mean, "seconds"
    print "Standard deviation:", stddev, "seconds"
  }
' "$time_log"
