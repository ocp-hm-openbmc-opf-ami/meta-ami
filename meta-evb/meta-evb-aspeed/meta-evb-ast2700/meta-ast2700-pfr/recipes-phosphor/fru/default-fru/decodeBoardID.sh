get_sku_signal_name() {
    local index="$1"
    echo "FM_BOARD_SKU_ID${index}"
}

is_partition_boot() {
    # shellcheck disable=SC2046
    [ "$(gpioget $(gpiofind "FM_DUAL_PARTITION_MODE_N"))" = 0 ]
}

is_board_eeprom_programmed() {
    local baseboard_fru_bus="0xf"
    local baseboard_fru_addr="0x50"
    local MRA_offset="0x05"
    local MRA_length="1"
    local length="0x8"

    # Multi-record area, last 8 bytes.
    local expected_fru_content="0x01 0x02 0x00 0x10 0x01 0x00 0x10 0xff"

    #read the Multi record area offset from common header
    local read_offset="$(i2cget -y $baseboard_fru_bus $baseboard_fru_addr $MRA_offset i $MRA_length)"

    #set read_offset to last 8 bytes of Multi record area
    read_offset="$((read_offset*8+8))"

    # Read the multi-record area from baseboard FRU.
    # shellcheck disable=SC2155
    local fru_content="$(i2cget -y $baseboard_fru_bus $baseboard_fru_addr $read_offset i $length)"

    [ "$fru_content" = "$expected_fru_content" ]
}

decode_board_id() {
    local board_id="$1"
    local name=
    local prod_id=
    case $board_id in
        32) name="BeechnutCity"
            prod_id="0x20";;
        37) name="BeechnutCityM"
            prod_id="0x25";;
        38) name="BNC XPV DUT"
            prod_id="0x26";;
        41) name="AvenueCity"
            prod_id="0x29";;
        42) name="AVC XPV DUT"
            prod_id="0x2A";;
        43) name="AVC 2SPC DUT"
            prod_id="0x2B";;
        45) name="AVC 2SPC LRP"
            prod_id="0x2D";;
        53) name="Kaseyville RP"
            prod_id="0xb4";;
        54) name="Kaseyville RP"
            prod_id="0xb5";;
        55) name="KVL XRP"
            prod_id="0xb6";;
        56) name="KVL PPV"
            prod_id="0xb7";;
    esac
    echo $name
    echo $prod_id
    echo true
}
