import logging
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


def analyse_results(args: dict):
    x_axis = 'test'
    y_axis = 'time'

    image_filename = '/tmp/final_{}_by_{}.png'.format(x_axis, y_axis)
    csv_filename = '/tmp/final.csv'

    if args.load_from_csv:
        objects = load_csv(csv_filename)
    else:
        keys = list_objects(args.prefix, args.local)
        objects = []
        for key in keys:
            data = get_object(key, args.local)
            print(data)
            save_file('/tmp/{}'.format(key), data.decode('utf-8'))
            obj = json.loads(data)
            objects.append(obj)
        save_csv(csv_filename, objects)

    df = pd.DataFrame(objects)

    # Convert 'time' to float
    df['time'] = df['time'].astype(float)

    print_fuzzer_misses(df)

    # Sort the DataFrame by 'mutant'
    df = df.sort_values(x_axis)

    # Create a boxplot
    fig, ax = plt.subplots(figsize=(15, 8))

    mutants = df[x_axis].unique()

    # Add alternating background colors
    for i in range(len(mutants)):
        if i % 2 == 0:
            ax.axvspan(i-0.5, i+0.5, facecolor='lightgrey', zorder=0)

    # Using seaborn to create boxplot as it supports creating multiple boxes for each category (tool for each mutant) directly
    sns.boxplot(data=df, x=x_axis, y=y_axis, hue='tool', ax=ax,
                flierprops=dict(markerfacecolor='gray', markersize=5), zorder=2)

    # Add stripplot to plot datapoints
    sns.stripplot(data=df, x=x_axis, y=y_axis, hue='tool',
                  dodge=True, linewidth=0.5, palette='dark', ax=ax, zorder=1)

    # Fetch legend handles and labels
    handles, labels = ax.get_legend_handles_labels()

    # Build a color dictionary for each tool
    tool_colors = {label: get_color(handle) for handle, label in zip(
        handles, labels) if label in df['tool'].unique()}

    # Set labels and title
    ax.set_xlabel(x_axis)
    ax.set_ylabel('Time to break invariants (seconds)')
    ax.set_title('Time to break invariants per {}'.format(x_axis))

    # Set y-axis to logarithmic scale
    ax.set_yscale("log")

    # Show legend
    ax.legend()

    # Find the lower limit for y
    y_lower = df[y_axis].min() / 10  # Adjust this divisor to suit your needs

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
                    df[x_axis] == mutant)][y_axis]
                data2 = df[(df['tool'] == tool2) & (
                    df[x_axis] == mutant)][y_axis]

                if len(data1) != 0 and len(data2) != 0:
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
                    print('winner {} {}'.format(mutant, winner))
                    # Format p-value to string rounded to 2 decimal places
                    p_str = "{:.2f}".format(p)

                    # Calculate the position for the annotation, position it in the center of each mutant group
                    mutant_index = list(df[x_axis].unique()).index(mutant)
                    # Annotate the p-value on the chart
                    ax.text(mutant_index, 0.05, f'p={p:0.2f}',
                            ha='center',
                            va='top',
                            transform=ax.get_xaxis_transform(),
                            bbox=dict(facecolor=color, alpha=0.5, edgecolor='black', linewidth=1))

    # Save the plot to a PNG file
    plt.tight_layout()
    plt.savefig(image_filename)


def get_color(obj):
    if isinstance(obj, patches.Rectangle):
        return obj.get_facecolor()
    elif isinstance(obj, mlines.Line2D):
        return obj.get_color()
    else:
        raise Exception("Object type not recognized")


def save_csv(filename: str, objects: List[dict]):
    fieldnames = ['job_id', 'tool', 'project', 'contract',
                  'test', 'tool_cmd', 'mutant', 'time', 'status']
    with open(filename, "w+", newline="") as csv_file:
        writer = csv.DictWriter(
            csv_file, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()  # Write the header
        for row in objects:
            writer.writerow(row)


def load_csv(filename: str) -> List[dict]:
    ans = []
    with open(filename, "r+", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            ans.append(row)
    return ans


def print_fuzzer_misses(df):
    logging.info("start fuzzer misses (halmos proved FALSE but fuzzer didn't)")
    grouped = df.groupby(['project', 'test', 'mutant'])

    for name, group in grouped:
        halmos_proved_false = group[(
            group['tool'] == 'halmos') & (group['status'] == '1')]
        if len(halmos_proved_false) > 0:
            print(group[['tool', 'test', 'mutant', 'status']])
    logging.info("end fuzzer misses")


def save_file(filename: str, data: str):
    with open(filename, "w+") as f:
        f.seek(0)
        f.write(data)
        f.close()
