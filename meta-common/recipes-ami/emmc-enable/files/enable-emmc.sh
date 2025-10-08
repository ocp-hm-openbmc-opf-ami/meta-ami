#!/bin/sh

CONFIG_FILE="/etc/sd_partition_info.conf"

if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE"
else
  echo "[ERROR] Config file $CONFIG_FILE not found."
  exit 1
fi

if [ -z "$DEVICE" ]; then
  echo "[ERROR] Value for DEVICE is not found."
  exit 1
fi

if [ -z "$NUM_PARTS" ]; then
  echo "[ERROR] Value for NUM_PARTS is not found."
  exit 1
fi

if [ -z "$PART_SIZES_MB" ]; then
  echo "[ERROR] Value for PART_SIZES_MB is not found."
  exit 1
fi

if [ -z "$PART_NAMES" ]; then
  echo "[ERROR] Value for PART_NAMES is not found."
  exit 1
fi

if [ -z "$PART_FS_TYPES" ]; then
  echo "[ERROR] Value for PART_FS_TYPES is not found."
  exit 1
fi

if [ -z "$MOUNT_PATHS" ]; then
  echo "[ERROR] Value for MOUNT_PATHS is not found."
  exit 1
fi

DRY_RUN=false

IFS=' ' read -r -a PART_SIZES <<< "$PART_SIZES_MB"
IFS=' ' read -r -a PART_NAMES_ARR <<< "$PART_NAMES"
IFS=' ' read -r -a PART_FS <<< "$PART_FS_TYPES"
IFS=' ' read -r -a MOUNT_PATHS_ARR <<< "$MOUNT_PATHS"

check_sd_card() {
  if [ ! -b "$DEVICE" ]; then
    echo "[FAIL] SD card not found at $DEVICE"
    exit 1
  fi
}

check_for_partition_table() {
  if ! fdisk -l "$DEVICE" &>/dev/null; then
    echo "[INFO] No partition table found. Creating a new one..."
    echo -e "o\nw" | fdisk "$DEVICE"
    sleep 1
  fi
}

get_total_size() {
  TOTAL_SIZE_BYTES=$(fdisk -l "$DEVICE" | grep "Disk $DEVICE:" | awk '{print $5}')
  TOTAL_SIZE_MB=$((TOTAL_SIZE_BYTES / 1024 / 1024))
  TOTAL_SIZE_SECTORS=$((TOTAL_SIZE_BYTES / 512))
  echo "[INFO] Total device size: ${TOTAL_SIZE_MB}MB"
}

calculate_required_space() {
  REQUIRED_SPACE_MB=0
  for SIZE in "${PART_SIZES[@]}"; do
    REQUIRED_SPACE_MB=$((REQUIRED_SPACE_MB + SIZE))
  done
  echo "[INFO] Required space: ${REQUIRED_SPACE_MB}MB"
}

get_existing_partitions() {
  EXISTING_PARTS=$(ls ${DEVICE}p* 2>/dev/null | sed -n 's/.*p\([0-9]\+\)$/\1/p' | sort -n)
}

check_space_availability() {
  if [ "$REQUIRED_SPACE_MB" -gt "$TOTAL_SIZE_MB" ]; then
    echo "[FAIL] Not enough space on SD card. Required: ${REQUIRED_SPACE_MB}MB, Available: ${TOTAL_SIZE_MB}MB"
    exit 1
  fi
}

format_and_mount_partitions() {
  MOUNT_OPTIONS="nosuid,nodev,noexec"
  for i in $(seq 1 $NUM_PARTS); do
    PART="${DEVICE}p$i"
    NAME="${PART_NAMES_ARR[$((i - 1))]}"
    FILESYSTEM="${PART_FS[$((i - 1))]}"
    MOUNT_PATH="${MOUNT_PATHS_ARR[$((i - 1))]}"

    if [ -b "$PART" ]; then
      CURRENT_FS=$(blkid "$PART" | grep -o 'TYPE="[^"]*"' | cut -d'"' -f2)
      if [ "$CURRENT_FS" != "$FILESYSTEM" ]; then
        if [ "$DRY_RUN" = true ]; then
          echo "[DRY-RUN] Would format $PART as $FILESYSTEM with label $NAME..."
        else
          echo "Formatting $PART as $FILESYSTEM with label $NAME..."
          if [ "$FILESYSTEM" = "vfat" ]; then
            mkfs.vfat -n "$NAME" "$PART"
          else
            mkfs."$FILESYSTEM" -L "$NAME" "$PART"
          fi
        fi
      fi

      mkdir -p "$MOUNT_PATH"
      if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would mount $PART at $MOUNT_PATH"
      else
        mount | grep -q "$PART" || mount -o $MOUNT_OPTIONS "$PART" "$MOUNT_PATH"
        echo "[MOUNT] Mounted $PART at $MOUNT_PATH"
      fi
    fi
  done
}

clean_partition() {
  PART=$1
  if [ -b "$PART" ]; then
    # Get the current filesystem type and format accordingly
    FSTYPE=$(blkid "$PART" | grep -o 'TYPE="[^"]*"' | cut -d'"' -f2)
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY-RUN] Would clean partition $PART with filesystem type $FSTYPE..."
    else
      echo "Cleaning partition $PART with filesystem type $FSTYPE..."
      mkfs."$FSTYPE" "$PART"
    fi
  else
    echo "Error: Partition $PART not found."
  fi
}

create_partitions() {
  echo "[INFO] Creating partitions..."
  PART_TABLE_TYPE=$(fdisk -l "$DEVICE" | grep -i "Disklabel type" | awk '{print $3}')
  USED_SECTORS=2048

  for i in $(seq 1 $NUM_PARTS); do
    PART_NUM=$i
    PART_PATH="${DEVICE}p$PART_NUM"
    SIZE_MB=${PART_SIZES[$((PART_NUM - 1))]}
    SIZE_SECTORS=$((SIZE_MB * 1024 * 1024 / 512))
    END_SECTOR=$((USED_SECTORS + SIZE_SECTORS - 1))

    if echo "$EXISTING_PARTS" | grep -q "^$PART_NUM$"; then
      echo "[SKIP] Partition $PART_PATH already exists."
    else
      if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would create partition $PART_PATH from $USED_SECTORS to $END_SECTOR..."
      else
        echo "[CREATE] Creating partition $PART_PATH..."
        echo -e "n\np\n$PART_NUM\n$USED_SECTORS\n$END_SECTOR\nw" | fdisk "$DEVICE"
      fi
    fi
    USED_SECTORS=$((END_SECTOR + 1))
  done

  if [ "$DRY_RUN" = false ]; then
    udevadm settle
    sleep 5

    for i in $(seq 1 $NUM_PARTS); do
      if [ ! -b "${DEVICE}p$i" ]; then
        echo "[ERROR] Partition ${DEVICE}p$i not found after rescan."
        exit 1
      fi
    done
  fi
}

main() {
  check_sd_card
  check_for_partition_table
  get_total_size
  get_existing_partitions
  calculate_required_space
  check_space_availability
  create_partitions
  format_and_mount_partitions

  for part in $CLEAN_PARTS; do
    clean_partition "$part"
  done

  echo "[DONE] All operations completed"
}

main

