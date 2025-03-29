import argparse
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime
import dateutil.parser
import os

# --- Parse Arguments ---
parser = argparse.ArgumentParser()
parser.add_argument('--prefix', default='')
parser.add_argument('--cpu')
parser.add_argument('--mem')
parser.add_argument('--power')
parser.add_argument('--vmstart')
parser.add_argument('--transcode1024start')
parser.add_argument('--transcode1024end')
parser.add_argument('--transcode2048start')
parser.add_argument('--transcode2048end')
parser.add_argument('--vmstop')
parser.add_argument('--output')
args = parser.parse_args()

# --- Helper to read marker timestamp ---
def read_marker(path):
    with open(path) as f:
        return dateutil.parser.parse(f.read().strip())

# --- Convert CSV to DataFrame ---
def read_typeperf_csv(path):
    df = pd.read_csv(path, skiprows=1)
    df.columns = ['Timestamp', 'Value']
    df['Timestamp'] = pd.to_datetime(df['Timestamp'])
    df['Value'] = pd.to_numeric(df['Value'], errors='coerce')
    return df.dropna()

# --- Load logs ---
cpu_df = read_typeperf_csv(args.cpu)
mem_df = read_typeperf_csv(args.mem)
power_df = read_typeperf_csv(args.power)

# --- Load markers ---
markers = {
    'VM Start': read_marker(args.vmstart),
    'Transcode 1024 Start': read_marker(args.transcode1024start),
    'Transcode 1024 End': read_marker(args.transcode1024end),
    'Transcode 2048 Start': read_marker(args.transcode2048start),
    'Transcode 2048 End': read_marker(args.transcode2048end),
    'VM Stop': read_marker(args.vmstop)
}


# --- Plotting Function ---
def plot_with_markers(df, ylabel, title, basename):
    filename = f"{args.prefix}_{basename}.png" if args.prefix else f"{basename}.png"
    filepath = os.path.join(args.output, filename)

    plt.figure(figsize=(12, 6))
    plt.plot(df['Timestamp'], df['Value'], label=ylabel)

    color_map = {
        'VM Start': 'green',
        'VM Stop': 'green',
        'Transcode 1024 Start': 'orange',
        'Transcode 1024 End': 'orange',
        'Transcode 2048 Start': 'purple',
        'Transcode 2048 End': 'purple'
    }


    for label, ts in markers.items():
        plt.axvline(ts, linestyle='--', color=color_map.get(label, 'black'), label=label)

    plt.xlabel('Time')
    plt.ylabel(ylabel)
    plt.title(title)
    plt.legend()
    plt.tight_layout()
    plt.savefig(filepath)
    plt.close()

# --- Generate Plots ---
plot_with_markers(cpu_df, 'CPU %', 'CPU Usage Over Time', 'cpu')
plot_with_markers(mem_df, 'Available Memory (MB)', 'Memory Usage Over Time', 'memory')
plot_with_markers(power_df, 'Power (Watts)', 'Power Usage Over Time', 'power')
