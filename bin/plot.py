#!/usr/bin/python3

# generate chart.svg for data

import csv
import sys
import numpy as np
import matplotlib.pyplot as plt

def read_csv(path):
  with open(sys.argv[1], newline = '') as fh:
    return list(reversed(list([row for row in csv.DictReader(fh)])))

# check arguments
if len(sys.argv) < 3:
  print("Usage: {} input.csv all-output.svg tiny-output.svg".format(sys.argv[0]))
  exit(-1)

# read csv
rows = read_csv(sys.argv[1])
lo_rows = [row for row in rows if (int(row['size']) <= 1024)]

# plot sizes
plt.barh(
  np.arange(len(rows)),
  [int(row['size']) for row in rows], 
  align = 'center',
  alpha = 0.5,
  tick_label = [('{} ({})'.format(row['name'], row['nice'])) for row in rows],
)

# add axes labels and title
plt.yticks(fontsize = 5)
plt.xlabel('Binary Size (bytes, log scale)')
plt.ylabel('Language and Build Method')
plt.xscale('log')
plt.title('All Static Binary Sizes', fontsize = 9)
plt.tight_layout()

# resize output figure
fig = plt.figure()
# plt.set_figwidth(6.4) # default 6.4
plt.set_figheight(6.4) # default 4.8

# save image
plt.savefig(sys.argv[2])

# clear plot
plt.clf()

# plot low sizes
plt.barh(
  np.arange(len(lo_rows)),
  [int(row['size']) for row in lo_rows], 
  align = 'center',
  alpha = 0.5,
  tick_label = [('{} ({})'.format(row['name'], row['nice'])) for row in lo_rows],
)

# add axes labels and title
plt.xlabel('Binary Size (bytes)')
plt.ylabel('Language and Build Method')
plt.xscale('linear')
plt.title('Tiny Static Binary Sizes (<1k)', fontsize = 9)
plt.tight_layout()

# save image
plt.savefig(sys.argv[3])
