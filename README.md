# Execution Timing Histogram Analysis

A set of MATLAB scripts that visualise execution time and execution cycle distributions from measurement data. The scripts read CSV sample files, generate histogram figures for overall, head (fastest), tail (slowest), per-scenario, and per-state distributions, and export a consolidated dataset.

All parameters -- platform name, cutoff thresholds, bin counts, and display options -- are configured through a single `.config` file. The scripts support any number of scenarios and automatically merge samples that share the same scenario name.

## Getting Started

### 1. Clone the repository

```bash
git clone git@github.com:therealmcfly/histogram-tool.git
cd histogram-tool
```

### 2. Place your sample data in `../samples/`

The scripts read CSV files from a `samples/` folder one level above the repository directory:

```
parent-directory/
├── samples/                    # Your CSV sample files go here
│   ├── NORMAL-00-et_log.csv
│   ├── NORMAL-01-et_log.csv
│   ├── BACK-00-et_log.csv
│   └── ...
└── histogram-tool/             # This repository
    ├── ec_histogram.m
    ├── et_histogram.m
    └── ...
```

Each CSV must contain the following columns:

| Column | Required by | Description |
|--------|-------------|-------------|
| `state` | Both scripts | State identifier (integer) |
| `et_ns` | `et_histogram.m` | Execution time in nanoseconds |
| `cycles` | `ec_histogram.m` | Execution cycle count |

Additional columns are ignored.

**Filename convention:** The scenario name is derived from the part of the filename before the first `-`. For example:

- `NORMAL-00-et_log.csv` --> scenario **NORMAL**
- `NORMAL-01-et_log.csv` --> scenario **NORMAL** (merged with the above)
- `BACK-00-et_log.csv` --> scenario **BACK**

Files with the same prefix are combined into a single scenario.

### 3. Create a `.config` file

The `.config` file is not tracked by git, so you must create it yourself. Create a file called `.config` in the repository root with the following contents:

```
# Histogram Configuration

PLATFORM_NAME = ARM

# Execution Cycle (EC) cutoffs
EC_TAIL_CUTOFF = 40000
EC_HEAD_CUTOFF = 3472

# Execution Time (ET) cutoffs
ET_TAIL_CUTOFF = 40000
ET_HEAD_CUTOFF = 3472

# Histogram bins
NBINS_MAIN = 50
NBINS_TAIL = 20
NBINS_HEAD = 20

# Display
LOGARITHMIC_SCALE = 1

# Overall title stats (1 = show, 0 = hide)
SHOW_COUNT = 1
SHOW_BEST_CASE = 1
SHOW_WORST_CASE = 1
SHOW_AVERAGE = 1
```

| Parameter | Description |
|-----------|-------------|
| `PLATFORM_NAME` | Platform identifier used in figure titles and exported filenames |
| `EC_TAIL_CUTOFF` / `ET_TAIL_CUTOFF` | Threshold for the tail (slow) distribution |
| `EC_HEAD_CUTOFF` / `ET_HEAD_CUTOFF` | Threshold for the head (fast) distribution |
| `NBINS_MAIN` | Number of bins for the overall histogram |
| `NBINS_TAIL` | Number of bins for the tail histogram |
| `NBINS_HEAD` | Number of bins for the head histogram |
| `LOGARITHMIC_SCALE` | `1` for log y-axis, `0` for linear |
| `SHOW_COUNT` | Show sample count in overall title |
| `SHOW_BEST_CASE` | Show best-case value in overall title |
| `SHOW_WORST_CASE` | Show worst-case value in overall title |
| `SHOW_AVERAGE` | Show average value in overall title |

### 4. Run in MATLAB

Open MATLAB, navigate to the `histogram-tool/` directory, and run:

```matlab
>> et_histogram   % for execution time (ns)
>> ec_histogram   % for execution cycles
```

## Output

**Figures (5 per script):**

1. **Overall distribution** -- full dataset with configurable stats in the title
2. **Head of distribution** -- samples below the head cutoff
3. **Tail of distribution** -- samples above the tail cutoff
4. **By scenario** -- one subplot per scenario
5. **By state** -- one subplot per state

**Exported CSV:**

A consolidated CSV is saved to `used-samples/<ddmmyy>/` with the format:

- `<PLATFORM>_all_et_samples_n<count>_<timestamp>.csv`
- `<PLATFORM>_all_ec_samples_n<count>_<timestamp>.csv`

The exported file contains all loaded samples with a `scenario` column.

## File Structure

```
parent-directory/
├── samples/                    # Input CSV files (external to repo)
└── histogram-tool/             # This repository
    ├── .config                 # Configuration file (not tracked, create manually)
    ├── read_config.m           # Config file parser
    ├── et_histogram.m          # Execution time analysis (ns)
    ├── ec_histogram.m          # Execution cycle analysis (cycles)
    ├── README.md
    └── used-samples/           # Exported datasets (not tracked by git)
        └── <ddmmyy>/
```
