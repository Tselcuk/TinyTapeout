#!/usr/bin/env python3
"""
Convert chevron CSV to Verilog chevron_row case statements.
"""

import csv
import sys
from pathlib import Path


def csv_to_chevron_rows(csv_path, width=85, height=100):
    """Convert CSV to Verilog chevron_row values."""
    # Read CSV and organize by row
    rows_data = {}
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            x = int(row['x'])
            y = int(row['y'])
            value = int(row['value'])
            
            if y not in rows_data:
                rows_data[y] = {}
            rows_data[y][x] = value
    
    # Generate bitmask for each row
    chevron_rows = []
    max_y = max(rows_data.keys())
    max_x = max(max(rows_data[y].keys()) for y in rows_data)
    
    print(f"CSV dimensions: {max_x + 1} x {max_y + 1}")
    print(f"Target dimensions: {width} x {height}")
    
    # Process rows (top to bottom)
    for row_idx in range(min(height, max_y + 1)):
        # Build bitmask (1 = white, 0 = black)
        bitmask = 0
        for x in range(min(width, max_x + 1)):
            if row_idx in rows_data and x in rows_data[row_idx]:
                value = rows_data[row_idx][x]
                if value == 1:  # White pixel
                    bitmask |= (1 << (width - 1 - x))
        
        chevron_rows.append((row_idx, bitmask))
    
    return chevron_rows


def generate_verilog_case(chevron_rows, width=85):
    """Generate Verilog case statement."""
    lines = []
    # Determine hex width needed (85 bits needs 22 hex digits, but we'll use 96 bits = 24 hex)
    hex_width = (width + 3) // 4  # Round up to nearest 4 bits
    if hex_width < 24:
        hex_width = 24  # Use 96 bits for consistency
    
    for idx, bitmask in chevron_rows:
        # Pad to 96 bits
        padded_mask = bitmask << (96 - width)
        hex_val = f"{padded_mask:024X}"
        lines.append(f"                7'd{idx}:  chevron_row = 96'h{hex_val};")
    
    return "\n".join(lines)


def main():
    csv_path = Path("docs/image/chevron.csv")
    
    if not csv_path.exists():
        print(f"Error: CSV file not found: {csv_path}", file=sys.stderr)
        sys.exit(1)
    
    chevron_rows = csv_to_chevron_rows(csv_path, width=85, height=100)
    verilog_code = generate_verilog_case(chevron_rows, width=85)
    
    print("\nVerilog case statements:\n")
    print(verilog_code)
    print("\n                default: chevron_row = 96'h000000000000000000000000;")


if __name__ == "__main__":
    main()

