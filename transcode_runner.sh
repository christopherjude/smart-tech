#!/bin/bash

# Ensure necessary directories exist
mkdir -p logs transcoded

# Define input videos and bitrates
VIDEOS=("complex_water_1080p" "simple_clock_1080p")
BITRATES=(1024 2048)
INPUT_DIR="resized_videos"

for VIDEO in "${VIDEOS[@]}"; do
  for BITRATE in "${BITRATES[@]}"; do
    # If argument is passed, only run matching bitrate
    if [[ -n "$1" && "$1" != "$BITRATE" ]]; then
      continue
    fi

    echo "=== Transcoding: $VIDEO @ ${BITRATE}Mbps ==="

    INPUT_FILE="${INPUT_DIR}/${VIDEO}.mp4"
    OUTPUT_FILE="transcoded/${VIDEO}_${BITRATE}Mbps.mp4"

    ffmpeg -y -i "$INPUT_FILE" -b:v ${BITRATE}M -bufsize ${BITRATE}M -maxrate ${BITRATE}M \
      -c:v libx264 -preset fast -c:a aac -b:a 192k "$OUTPUT_FILE"

    echo "Done: $VIDEO @ ${BITRATE}Mbps"
  done
done


echo "All transcoding complete."
