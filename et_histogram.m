%% Prepare workspace
clear
clc
close all

%% Configuration
cfg = read_config('histogram.config');
PLATFORM_NAME     = cfg.PLATFORM_NAME;
TAIL_CUTOFF       = cfg.ET_TAIL_CUTOFF;
HEAD_CUTOFF       = cfg.ET_HEAD_CUTOFF;
NBINS_MAIN        = cfg.NBINS_MAIN;
NBINS_TAIL        = cfg.NBINS_TAIL;
NBINS_HEAD        = cfg.NBINS_HEAD;
LOGARITHMIC_SCALE = cfg.LOGARITHMIC_SCALE;

%% Data Initialization
samples_folder = fullfile('..', 'samples');
if ~exist(samples_folder, 'dir')
    error('Samples folder "%s" does not exist.', samples_folder);
end

files = dir(fullfile(samples_folder, '*.csv'));
if isempty(files)
    error('No CSV files found in "%s".', samples_folder);
end

% Predefine table structure
all_et = table( ...
    [], [], [], {}, ...
    'VariableNames', {'et','state','scenario','scenario_name'} );

scenario_map = containers.Map();
scenario_count = 0;

for k = 1:numel(files)
    fname = fullfile(samples_folder, files(k).name);
    T = readtable(fname);

    % Require et_ns and state
    if ~all(ismember({'et_ns','state'}, T.Properties.VariableNames))
        warning('Skipping %s (missing et_ns or state)', files(k).name);
        continue;
    end

    % Scenario name from filename (e.g. BACK from BACK-00-et_log.csv)
    tokens = regexp(files(k).name, '^([^-]+)', 'tokens');
    scenario_name = upper(tokens{1}{1});

    % Assign consistent scenario ID per name
    if ~scenario_map.isKey(scenario_name)
        scenario_count = scenario_count + 1;
        scenario_map(scenario_name) = scenario_count;
    end
    scenario_id = scenario_map(scenario_name);

    sub = table( ...
        T.et_ns, ...
        T.state, ...
        repmat(scenario_id, height(T), 1), ...
        repmat({scenario_name}, height(T), 1), ...
        'VariableNames', {'et','state','scenario','scenario_name'} );

    all_et = [all_et; sub];
end

% Fail early if nothing loaded
if isempty(all_et)
    error('No valid CSV data loaded. Check CSV headers.');
end

%% Export combined CSV
out_dir = fullfile('used-samples', datestr(now, 'ddmmyy'));
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
out_name = fullfile(out_dir, sprintf('%s_all_et_samples_n%d_%s.csv', PLATFORM_NAME, height(all_et), datestr(now, 'yyyymmdd_HHMMSS')));
writetable(all_et, out_name);
fprintf('Exported %d rows to %s\n', height(all_et), out_name);

%% 1. Overall histogram
global_wcet = max(all_et.et);
bcet = min(all_et.et);
fprintf('Global WCET = %d ns\n', global_wcet);

figure;
histogram(all_et.et, NBINS_MAIN, 'Normalization', 'count');

ax = gca;
ax.XAxis.Exponent = 0;   % remove ×10^n
xtickformat('%.0f');    % show integers only

if LOGARITHMIC_SCALE
    set(gca, 'YScale', 'log');
end

xlabel('Execution time (ns)');
ylabel('Count');
title(sprintf('Overall Execution Time Distribution (n = %d, BCET = %d, WCET = %d)', height(all_et), bcet, global_wcet));
grid on;
xline(global_wcet, 'r', 'LineWidth', 2, 'Label', 'WCET');

%% 2. Head histogram
head_samples = all_et.et(all_et.et <= HEAD_CUTOFF);
fprintf('Head samples: %d entries (<= %d ns, BCET = %d)\n', ...
    numel(head_samples), HEAD_CUTOFF, bcet);

figure;
histogram(head_samples, NBINS_HEAD);
xlabel('Execution time (ns)');
ylabel('Frequency');
title(sprintf('Head of Distribution (\\leq %d, n = %d, BCET = %d)', HEAD_CUTOFF, numel(head_samples), bcet));
grid on;
xline(bcet, 'g', 'LineWidth', 2, 'Label', 'BCET');

%% 3. Tail histogram
tail_samples = all_et.et(all_et.et > TAIL_CUTOFF);

figure;
histogram(tail_samples, NBINS_TAIL);
xlabel('Execution time (ns)');
ylabel('Frequency');
title(sprintf('Tail of Distribution (> %d, n = %d, WCET = %d)', TAIL_CUTOFF, numel(tail_samples), global_wcet));
grid on;
xline(global_wcet, 'r', 'LineWidth', 2, 'Label', 'WCET');

%% 4. Histograms by scenario
scenarios = unique(all_et.scenario);

figure;
for i = 1:numel(scenarios)
    sc = scenarios(i);
    et_sc = all_et.et(all_et.scenario == sc);
    sc_name = all_et.scenario_name{find(all_et.scenario == sc, 1)};

    wcet_sc = max(et_sc);

    subplot(ceil(numel(scenarios)/2), 2, i);
    histogram(et_sc, 50);

    if LOGARITHMIC_SCALE
        set(gca, 'YScale', 'log');
    end

    xlabel('Execution time (ns)');
    ylabel('Frequency');
    title(sprintf('%s (WCET = %d)', sc_name, wcet_sc));
    grid on;

    xline(wcet_sc, 'r', 'LineWidth', 2, 'Label', 'WCET');
end
sgtitle('Execution Time by Scenario');

%% 5. Histograms by state
state_names = {'Learning','Detecting','Ignoring','Pacing'};
states = unique(all_et.state);

figure;
for i = 1:numel(states)
    st = states(i);
    et_st = all_et.et(all_et.state == st);

    wcet_st = max(et_st);

    subplot(2,2,st+1);
    histogram(et_st, 50);

    if LOGARITHMIC_SCALE
        set(gca, 'YScale', 'log');
    end

    xlabel('Execution time (ns)');
    ylabel('Frequency');
    title(sprintf('%s (WCET = %d)', ...
        state_names{st+1}, wcet_st));
    grid on;

    xline(wcet_st, 'r', 'LineWidth', 2, 'Label', 'WCET');
end
sgtitle('Execution Time by State');
