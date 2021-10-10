#!/usr/bin/env python3

import sys
import os
# pip3 install deluge-client
from deluge_client import LocalDelugeRPCClient

html_full_screen_table_template = '<table class="table table-condensed table-striped">\n'
html_full_screen_table_template += '<tr><th>Torrent</th><th class="text-right" style="width:100px">Size</th>'
html_full_screen_table_template += '<th class="text-right" style="width:100px">Down speed</th><th>ETA</th><th>Progress</th></tr>\n'
html_full_screen_table_template += '{}</table>\n'
html_full_screen_table_template += '<script>$(function () {{ $(\'[data-toggle="tooltip"]\').tooltip({{container: \'body\'}}) }});</script>'

html_home_screen_table_template = '<table class="table table-condensed">\n'
html_home_screen_table_template += '<tr><th>Torrent</th><th>Progress</th></tr>\n'
html_home_screen_table_template += '{}</table>\n'
html_home_screen_table_template += '<script>$(function () {{ $(\'[data-toggle="tooltip"]\').tooltip({{container: \'body\'}}) }});</script>'

# Valid torrent states:
    # if state == 'Active':
    # if state == 'Allocating':
    # if state == 'Checking':
    # if state == 'Downloading':
    # if state == 'Seeding':
    # if state == 'Paused':
    # if state == 'Error':
    # if state == 'Queued':
    # if state == 'Moving':

def format_size(size_bytes):
    label = 'B'
    size = size_bytes
    if size > 100:
        size /= 1024
        label = 'KB'
    if size > 100:
        size /= 1024
        label = 'MB'
    if size > 100:
        size /= 1024
        label = 'GB'
    if size > 100:
        size /= 1024
        label = 'TB'
    return '%.1f %s' % (size,label)

def format_time(time_seconds):
    label = 's'
    time = time_seconds
    if time > 60:
        label = 'm'
        time /= 60
    if time > 60:
        label = 'h'
        time /= 60
    ret = '%d%s' % (time, label)
    if label == 'h':
        time_minutes = time_seconds-(int(time)*60*60)
        ret += format_time(time_minutes)
    return ret

def get_html_progress_bar(torrent, text=None):
    progress = torrent['progress']
    state = torrent['state']
    progress_pct = ('%.2f' if progress < 100 else '%.0f') % progress
    if not text:
        text = progress_pct + '%'
    html = '<div class="progress" style="margin:0;">'
    html += '<div class="progress-bar '
    if state == 'Error':
        html += 'progress-bar-danger'
    elif state == 'Downloading':
        html += 'progress-bar-striped active'
    elif state == 'Paused':
        html += 'progress-bar-warning'
    elif progress == 100:
        html += 'progress-bar-success'
    html += '" role="progressbar" aria-valuemin="0" aria-valuemax="100" '
    html += ' data-toggle="tooltip" title="' + torrent['state'] + '"'
    html += 'aria-valuenow="'+progress_pct+'" style="width: '+progress_pct+'%;">'+text+'</div>'
    html += '</div>'
    return html

def get_deluge_info():
    with LocalDelugeRPCClient() as client:
        torrent_list = client.call('core.get_torrents_status', {}, ['name','time_added','progress','state','total_done','total_size','download_location','eta','peers'])
        session_status = client.call('core.get_session_status', ['download_rate', 'upload_rate'])
    return {
        'torrents': torrent_list,
        'session': session_status,
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <path>")
        sys.exit()
    
    output_path = sys.argv[1]
    print('Will generate output in '+output_path)

    deluge_info = get_deluge_info()
    session_status = deluge_info['session']
    if 'download_rate' in session_status:
        print('Download rate: ' + str(session_status['download_rate']))
        with open(os.path.join(output_path, 'download_rate.txt'), 'w') as f:
            f.write(str(session_status['download_rate']))
    if 'upload_rate' in session_status:
        print('Upload rate: ' + str(session_status['upload_rate']))
        with open(os.path.join(output_path, 'upload_rate.txt'), 'w') as f:
            f.write(str(session_status['upload_rate']))

    torrent_list = deluge_info['torrents']
    print('Found {} torrents'.format(len(torrent_list)))
    sorted_torrents = sorted(torrent_list.items(), key=lambda x: x[1]['time_added'], reverse=True)

    css_name_cell_home_table = 'overflow:hidden;text-overflow:ellipsis;max-width:340px;'

    html_full = ''
    html_home = ''
    count = 0
    for torrent_hash,torrent in sorted_torrents:
        count += 1
        down_speed = 0
        # up_speed = 0
        if 'peers' in torrent and torrent['peers']:
            for peer in torrent['peers']:
                down_speed += peer['down_speed']
                # up_speed += peer['up_speed']
        
        html_full += f"<tr id=\"torrent_{torrent_hash}\">"
        html_full += f"<td title=\"{torrent['download_location']}\">{torrent['name']}</td>" # Name
        html_full += '<td class="text-right">' + format_size(torrent['total_size']) + '</td>' # Size
        html_full += '<td class="text-right">' + (format_size(down_speed) + '/s' if down_speed else '') + '</td>' # Down speed
        html_full += '<td>' + (format_time(torrent['eta']) if torrent['eta'] else '') + '</td>' # ETA
        html_full += '<td>' + get_html_progress_bar(torrent) + '</td>' # Progress
        html_full += "</tr>\n"

        if count <= 4:
            html_home += f"<tr id=\"torrent_{torrent_hash}\">"
            # Name
            html_home += f"<td style=\"{css_name_cell_home_table}\"><span title=\"{torrent['download_location']}\">{torrent['name']}</span><br>"
            html_home += f"<small title=\"{torrent['download_location']}\">{torrent['download_location']}</small></td>"
            # Progress
            html_home += '<td>' + get_html_progress_bar(torrent, format_size(torrent['total_done'])) + '</td>'
            html_home += "</tr>\n"
    
    if count > 4:
        html_home += '<tr><td colspan="2"><a href="addons.html?activePage=2">View all {} entries</a></td></tr>'.format(count)
    
    html_full = html_full_screen_table_template.format(html_full)
    html_home = html_home_screen_table_template.format(html_home)

    print('Writing HTML output files')

    with open(os.path.join(output_path, 'torrents_home.html'), 'w') as f:
        f.write(html_home)
    with open(os.path.join(output_path, 'deluge.html'), 'w') as f:
        f.write(html_full)

    print('Finished successfully')
