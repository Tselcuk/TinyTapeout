#!/usr/bin/env python3
"""
Convert a bitmap image to CSV with black/white pixel values.

Usage:
    python bitmap_to_bw_csv.py <input_image> [output_csv] [--threshold THRESHOLD]
    
Output CSV format:
    x, y, value
    where value is 0 for black and 1 for white
"""

import sys
import argparse
from pathlib import Path
from PIL import Image
import numpy as np


def image_to_bw_csv(input_path, output_path=None, threshold=128):
    """Convert an image to CSV with black/white pixel values."""
    # Open the image
    img = Image.open(input_path)
    
    # Convert to grayscale if needed
    if img.mode != 'L':
        img = img.convert('L')
    
    width, height = img.size
    
    # Convert to numpy array for easier processing
    img_array = np.array(img)
    
    # Apply threshold: values >= threshold become white (1), else black (0)
    bw_array = (img_array >= threshold).astype(int)
    
    # Determine output path
    if output_path is None:
        output_path = Path(input_path).with_suffix('.csv')
    else:
        output_path = Path(output_path)
    
    # Write CSV header
    with open(output_path, 'w') as f:
        f.write("x,y,value\n")
        
        # Iterate through each pixel
        for y in range(height):
            for x in range(width):
                value = int(bw_array[y, x])
                f.write(f"{x},{y},{value}\n")
    
    # Print statistics
    black_count = np.sum(bw_array == 0)
    white_count = np.sum(bw_array == 1)
    total_pixels = width * height
    
    print(f"Converted {width}x{height} image to {output_path}")
    print(f"Total pixels: {total_pixels}")
    print(f"Black pixels (0): {black_count} ({100*black_count/total_pixels:.1f}%)")
    print(f"White pixels (1): {white_count} ({100*white_count/total_pixels:.1f}%)")
    print(f"Threshold used: {threshold}")


def main():
    parser = argparse.ArgumentParser(
        description="Convert a bitmap image to CSV with black/white pixel values"
    )
    parser.add_argument(
        'input',
        help='Input image file path'
    )
    parser.add_argument(
        'output',
        nargs='?',
        default=None,
        help='Output CSV file path (default: input filename with .csv extension)'
    )
    parser.add_argument(
        '--threshold',
        type=int,
        default=128,
        help='Grayscale threshold value (0-255). Pixels >= threshold become white (1), else black (0). Default: 128'
    )
    
    args = parser.parse_args()
    
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file '{input_path}' not found", file=sys.stderr)
        sys.exit(1)
    
    if not (0 <= args.threshold <= 255):
        print(f"Error: Threshold must be between 0 and 255", file=sys.stderr)
        sys.exit(1)
    
    try:
        image_to_bw_csv(input_path, args.output, args.threshold)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

