python do_ipmb_channels:append() {
    path = os.path.join(d.getVar('D') + d.getVar('datadir'),
                        'ipmbbridge', 'ipmb-channels.json')

    with open(path, 'r', encoding='utf-8') as config_file:
        data = json.load(config_file)

    for channel in data.get('channels', []):
        if channel.get('slave-path') == '/dev/ipmb-4':
            channel['type'] = 'me'
            break
    else:
        bb.fatal('TiogaPass ME channel /dev/ipmb-4 is missing')

    with open(path, 'w', encoding='utf-8') as config_file:
        json.dump(data, config_file, indent=4)
}