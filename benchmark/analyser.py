from typing import List
from .storage import get_object, list_objects
import csv
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
import matplotlib.patches as patches
import numpy as np
import pandas as pd
import seaborn as sns
from scipy.stats import mannwhitneyu
import json

image_filename = '/tmp/final.png'
csv_filename = '/tmp/final.csv'

def analyse_results(args: dict):
    if args.load_from_csv:
        objects = load_csv()
    else:
        keys = list_objects(args.prefix, args.local)
        objects = []
        for key in keys:
            data = get_object(key, args.local)
            obj = json.loads(data)
            objects.append(obj)
        save_csv(objects)

    df = pd.DataFrame(objects)
    # Sort the DataFrame by 'mutant'
    df = df.sort_values('mutant')

    # Create a boxplot
    fig, ax = plt.subplots(figsize=(15, 8))

    mutants = df['mutant'].unique()

    # Add alternating background colors
    for i in range(len(mutants)):
        if i % 2 == 0:
            ax.axvspan(i-0.5, i+0.5, facecolor='lightgrey', zorder=0)

    # Using seaborn to create boxplot as it supports creating multiple boxes for each category (tool for each mutant) directly
    sns.boxplot(data=df, x='mutant', y='time', hue='tool', ax=ax,
                flierprops=dict(markerfacecolor='gray', markersize=5), zorder=2)

    # Add stripplot to plot datapoints
    sns.stripplot(data=df, x='mutant', y='time', hue='tool',
                  dodge=True, linewidth=0.5, palette='dark', ax=ax, zorder=1)

    # Fetch legend handles and labels
    handles, labels = ax.get_legend_handles_labels()

    # Build a color dictionary for each tool
    tool_colors = {label: get_color(handle) for handle, label in zip(
        handles, labels) if label in df['tool'].unique()}

    # Set labels and title
    ax.set_xlabel('Mutant')
    ax.set_ylabel('Time to break invariants (seconds)')
    ax.set_title('Time to break invariants per Mutant')

    # Set y-axis to logarithmic scale
    ax.set_yscale("log")

    # Show legend
    ax.legend()

    # Find the lower limit for y
    y_lower = df['time'].min() / 10  # Adjust this divisor to suit your needs

    # Set the y-axis limit
    ax.set_ylim(bottom=y_lower)

    tools = df['tool'].unique()

    # For each mutant and tool, perform the Mann-Whitney U Test
    for mutant in mutants:
        for i in range(len(tools)):
            for j in range(i+1, len(tools)):
                tool1 = tools[i]
                tool2 = tools[j]

                data1 = df[(df['tool'] == tool1) & (
                    df['mutant'] == mutant)]['time']
                data2 = df[(df['tool'] == tool2) & (
                    df['mutant'] == mutant)]['time']

                # Perform the test
                stat, p = mannwhitneyu(data1, data2)

                if p > 0.05:
                    winner = 'N/A'
                    color = 'gray'  # Choose a default color when there's no significant difference
                else:
                    if data1.median() < data2.median():
                        winner = tool1
                    else:
                        winner = tool2
                    # Get the color of the winning tool
                    color = tool_colors[winner]
                print('mutant {} winner {}'.format(mutant, winner))
                # Format p-value to string rounded to 2 decimal places
                p_str = "{:.2f}".format(p)

                # Calculate the position for the annotation, position it in the center of each mutant group
                mutant_index = list(df['mutant'].unique()).index(mutant)
                # Annotate the p-value on the chart
                ax.text(mutant_index, 0.05, f'p={p:0.2f}',
                        ha='center',
                        va='top',
                        transform=ax.get_xaxis_transform(),
                        bbox=dict(facecolor=color, alpha=0.5, edgecolor='black', linewidth=1))

    # Save the plot to a PNG file
    plt.tight_layout()
    plt.savefig("/tmp/final.png")


def get_color(obj):
    if isinstance(obj, patches.Rectangle):
        return obj.get_facecolor()
    elif isinstance(obj, mlines.Line2D):
        return obj.get_color()
    else:
        raise Exception("Object type not recognized")


def save_csv(objects: List[dict]):
    fieldnames = ['job_id', 'tool', 'project', 'contract',
                  'test', 'tool_cmd', 'mutant', 'time', 'status']
    with open(csv_filename, "w+", newline="") as csv_file:
        writer = csv.DictWriter(
            csv_file, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()  # Write the header
        for row in objects:
            writer.writerow(row)

def load_csv() -> List[dict]:
    ans = []
    with open(csv_filename, "r+", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            ans.append(row)
    return ans

