#!/usr/bin/env python3

def parse_synthesis_log(log_file):
    with open(log_file, 'r') as f:
        lines = f.readlines()

    start_index = None
    end_index = None

    # Find the start and end indices of the cell usage table
    for i, line in enumerate(lines):
        if line.strip() == 'Report Cell Usage:':
            start_index = i + 2
        elif start_index is not None and line.strip() == '':
            end_index = i
            break

    if start_index is None or end_index is None:
        print("Cell usage table not found in the synthesis log.")
        return None

    cell_usage_lines = lines[start_index:end_index]

    cell_usage = []

    for line in cell_usage_lines:
        parts = line.strip().split('|')
        cell_type = parts[2].strip()
        count = parts[3].strip()
        if count.isdigit():  # Check if count is a valid integer
            cell_usage.append((cell_type, int(count)))
        else:
            print(f"Invalid count value found: {count}")
            return None

    return cell_usage


def calculate_percentage(cell_usage, total_cells):
    percentages = []
    for cell_type, count in cell_usage:
        percentage = (count / total_cells) * 100
        percentages.append(percentage)
    return percentages

def add_percentage_column(cell_usage, percentages):
    for i, (cell_type, count) in enumerate(cell_usage):
        percentage = percentages[i]
        cell_usage[i] = (cell_type, count, f"{percentage:.2f}%")
    return cell_usage

def print_table(cell_usage):
    print("+------+---------+------+------------+")
    print("|Index | Cell    |Count | Percentage |")
    print("+------+---------+------+------------+")
    for i, (cell_type, count, percentage) in enumerate(cell_usage, start=1):
        print(f"|{i:<6}|{cell_type:<9}|{count:<6}|{percentage:>11}|")
    print("+------+---------+------+------------+")

def main():
    log_file = 'work/vivado_synth.log'
    cell_usage, total_cells = parse_synthesis_log(log_file)
    if cell_usage is not None:
        percentages = calculate_percentage(cell_usage, total_cells)
        cell_usage_with_percentage = add_percentage_column(cell_usage, percentages)
        print_table(cell_usage_with_percentage)

if __name__ == "__main__":
    main()

