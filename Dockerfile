FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Set hostname
RUN echo "docker-env-ubuntu" > /etc/hostname

# Create user and home directory
RUN useradd -ms /bin/bash s4325535

# Install necessary tools
RUN apt update && \
    apt install -y ffmpeg wget tree

# Create project folder as root first
RUN mkdir -p /home/s4325535/CSI_6_SIT && \
    chown -R s4325535:s4325535 /home/s4325535/CSI_6_SIT

# Switch to user and set working directory
USER s4325535
WORKDIR /home/s4325535/CSI_6_SIT

# Copy videos from local folder to container
COPY original_videos/ ./original_videos/
COPY transcode_runner.sh ./transcode_runner.sh

# Create resized_videos folder and run resizing
RUN mkdir -p resized_videos && \
    for file in original_videos/*.mp4; do \
        filename=$(basename "$file" .mp4); \
        ffmpeg -y -i "$file" -vf scale=1920:1080 "resized_videos/${filename}_1080p.mp4"; \
    done

# Default shell
CMD ["/bin/bash"]
