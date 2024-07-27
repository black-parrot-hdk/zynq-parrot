import argparse
import matplotlib.pyplot as plt

def read_hex_file(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
    hex_numbers = [line.strip() for line in lines]
    return hex_numbers

def count_unique_numbers(hex_numbers):
    unique_numbers = set()
    unique_counts = []
    for number in hex_numbers:
        unique_numbers.add(number)
        unique_counts.append(len(unique_numbers))
    return unique_counts

def plot_unique_hex_counts(file_paths):
    markers = ['o', 's', '^', 'D', 'v', '<', '>', 'p', '*', 'h']  # List of markers to use
    plt.figure(figsize=(10, 6))
    
    for i, file_path in enumerate(file_paths):
        hex_numbers = read_hex_file(file_path)
        unique_counts = count_unique_numbers(hex_numbers)
        line_numbers = list(range(1, len(unique_counts) + 1))
        
        plt.plot(line_numbers, unique_counts, marker=markers[i % len(markers)], 
                 markevery=max(1, len(line_numbers)//10), label=file_path)
    
    plt.xlabel('Line Number')
    plt.ylabel('Number of Unique Hex Numbers')
    plt.title('Number of Unique Hex Numbers Found vs. Line Number')
    plt.legend()
    plt.grid(True)
    plt.show()

def main():
    parser = argparse.ArgumentParser(description='Plot the number of unique hex numbers found versus file line number.')
    parser.add_argument('files', metavar='F', type=str, nargs='+', help='Input files containing hex numbers')

    args = parser.parse_args()
    
    plot_unique_hex_counts(args.files)

if __name__ == "__main__":
    main()
