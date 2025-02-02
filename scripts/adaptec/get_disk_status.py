"""
Prerequisites:

* Adaptec RAID controller hardware installed in system. 
* Adaptec RAID controller driver is installed locally. 
* arcconf.exe tool accessible in current directory or in PATH. 

NOTES:

* -- This script must be run with Administrator privileges --
* Tested on Windows 11 Pro with Adaptec 5805ZQ RAID controller.
* Ran on Python 3.13
"""

import re
import subprocess
import xml.etree.ElementTree as ET

# SMART attribute descriptions mapping
smart_attribute_descriptions = {
    "0x01": "Read Error Rate",
    "0x02": "Throughput Performance",
    "0x03": "Spin-Up Time",
    "0x04": "Start/Stop Count",
    "0x05": "Reallocated Sector Count",
    "0x07": "Seek Error Rate",
    "0x08": "Seek Time Performance",
    "0x09": "Power-On Hours",
    "0x0A": "Spin Retry Count",
    "0x0C": "Power Cycle Count",
    "0x0D": "Soft Read Error Rate",
    "0x0E": "Temperature",
    "0x10": "Hardware ECC Recovered",
    "0x11": "Reallocation Event Count",
    "0x12": "Current Pending Sector Count",
    "0x13": "Uncorrectable Sector Count",
    "0x15": "Program Fail Count",
    "0x16": "Erase Fail Count",
    "0x17": "Runtime Bad Block",
    "0x18": "End-to-End Error",
    "0x1D": "Soft ECC Correction",
    "0x1E": "Reported Uncorrectable Errors",
    "0x24": "Mechanical Hours",
    "0x27": "Airflow Temperature",
    "0x28": "Drive Temperature",
    "0x29": "Hardware ECC Recovered",
    "0x2A": "Total LBAs Written",
    "0x2B": "Total LBAs Read",
    "0x2C": "Total LBAs Written Expanded",
    "0x2D": "Total LBAs Read Expanded",
    "0x2E": "Data Units Read",
    "0x2F": "Data Units Written",
    "0x30": "Head Flying Hours",
    "0x31": "Total LBAs Written Expanded",
    "0x32": "Total LBAs Read Expanded",
    "0x33": "Total LBAs Read Expanded",
    "0x34": "Total LBAs Written Expanded",
    "0x35": "Total LBAs Read Expanded",
    "0x36": "Total LBAs Written Expanded",
    "0x37": "Total LBAs Read Expanded",
    "0x38": "Total LBAs Written Expanded",
    "0x39": "Total LBAs Read Expanded",
    "0x3A": "Total LBAs Written Expanded"
}

def check_controller(controller_id):
    cmd = ['arcconf', 'GETSMARTSTATS', str(controller_id)]
    result = subprocess.run(cmd, capture_output=True, text=True)
    output = result.stdout

    # Extract XML part
    start_tag = '<SmartStats'
    end_tag = '</SmartStats>'
    start_idx = output.find(start_tag)
    if start_idx == -1:
        print(f"No SMART stats found for controller {controller_id}")
        return []
    end_idx = output.find(end_tag, start_idx)
    if end_idx == -1:
        print(f"Malformed XML for controller {controller_id}")
        return []
    end_idx += len(end_tag)
    xml_content = output[start_idx:end_idx]

    try:
        root = ET.fromstring(xml_content)
    except ET.ParseError as e:
        print(f"Error parsing XML for controller {controller_id}: {e}")
        return []

    failing_disks = []

    for disk in root.findall('.//PhysicalDriveSmartStats'):
        channel = disk.get('channel')
        drive_id = disk.get('id')
        failing_attrs = []
        
        for attr in disk.findall('Attribute'):
            attr_id = attr.get('id')
            description = smart_attribute_descriptions.get(attr_id, "Unknown Attribute")
            
            nc = attr.get('normalizedCurrent')
            th = attr.get('threshold')
            if nc is None or th is None:
                continue
            
            try:
                norm_current = int(nc)
                threshold = int(th)
            except ValueError:
                continue

            if threshold > 0 and norm_current < threshold:
                failing_attrs.append({
                    'attribute': description,
                    'id': attr_id,
                    'normalized': norm_current,
                    'threshold': threshold
                })

        if failing_attrs:
            failing_disks.append({
                'channel': channel,
                'id': drive_id,
                'attributes': failing_attrs
            })
    
    return failing_disks

def get_controller_ids():
    cmd = ['arcconf', 'GETVERSION']
    result = subprocess.run(cmd, capture_output=True, text=True)
    output = result.stdout

    controller_ids = []
    for line in output.splitlines():
        match = re.match(r'Controller #(\d+)', line)
        if match:
            controller_ids.append(int(match.group(1)))

    return controller_ids

def main():
    print("SMART Attribute Status Check\n" + "="*40)
    controller_ids = get_controller_ids()
    if not controller_ids:
        print("No controllers found.")
        return

    for controller_id in controller_ids:
        print(f"\nChecking Controller {controller_id}...")
        failing_disks = check_controller(controller_id)
        
        if not failing_disks:
            print(f"  ✅ All disks healthy on controller {controller_id}")
            continue
            
        print(f"  ⚠️  Potential issues found on controller {controller_id}:")
        for disk in failing_disks:
            print(f"\n    Disk Channel {disk['channel']}, ID {disk['id']}")
            for attr in disk['attributes']:
                print(f"      • {attr['attribute']} ({attr['id']}):")
                print(f"        Current: {attr['normalized']} | Threshold: {attr['threshold']}")
                print(f"        Status: WARNING - Value below threshold!")

if __name__ == "__main__":
    main()
