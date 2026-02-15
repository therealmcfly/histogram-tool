%% Prepare workspace
clear
clc
close all

%% Configuration
cfg = read_config('histogram.config');
PLATFORM_NAME     = cfg.PLATFORM_NAME;
TAIL_CUTOFF       = cfg.EC_TAIL_CUTOFF;
HEAD_CUTOFF       = cfg.EC_HEAD_CUTOFF;
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
all_ec = table( ...
    [], [], {}, ...
    'VariableNames', {'ec','state','scenario'} );

for k = 1:numel(files)
    fname = fullfile(samples_folder, files(k).name);
    T = readtable(fname);

    % Require cycles and state
    if ~all(ismember({'cycles','state'}, T.Properties.VariableNames))
        warning('Skipping %s (missing cycles or state)', files(k).name);
        continue;
    end

    % Scenario name from filename (e.g. BACK from BACK-00-et_log.csv)
    tokens = regexp(files(k).name, '^([^-]+)', 'tokens');
    scenario_name = upper(tokens{1}{1});

    sub = table( ...
        T.cycles, ...
        T.state, ...
        repmat({scenario_name}, height(T), 1), ...
        'VariableNames', {'ec','state','scenario'} );

    all_ec = [all_ec; sub];
end

% Fail early if nothing loaded
if isempty(all_ec)
    error('No valid CSV data loaded. Check CSV headers.');
end

%% Export combined CSV
out_dir = fullfile('used-samples', datestr(now, 'ddmmyy'));
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
out_name = fullfile(out_dir, sprintf('%s_all_ec_samples_n%d_%s.csv', PLATFORM_NAME, height(all_ec), datestr(now, 'yyyymmdd_HHMMSS')));
writetable(all_ec, out_name);
fprintf('Exported %d rows to %s\n', height(all_ec), out_name);

%% 1. Overall histogram
global_wcec = max(all_ec.ec);
bcec = min(all_ec.ec);
fprintf('Global WCEC = %d cycles\n', global_wcec);

figure;
histogram(all_ec.ec, NBINS_MAIN, 'Normalization', 'count');

ax = gca;
ax.XAxis.Exponent = 0;   % remove ×10^n
xtickformat('%.0f');    % show integers only

if LOGARITHMIC_SCALE
    set(gca, 'YScale', 'log');
end

xlabel('Execution cycle');
ylabel('Count');
title(sprintf('Execution Cycle Distribution on %s\n(n = %d, Best-Case = %d, Worst-Case = %d)', PLATFORM_NAME, height(all_ec), bcec, global_wcec));
grid on;
xline(global_wcec, 'r', 'LineWidth', 2, 'Label', 'Worst-Case');

%% 2. Head histogram
head_samples = all_ec.ec(all_ec.ec <= HEAD_CUTOFF);
fprintf('Head samples: %d entries (<= %d cycles, BCEC = %d)\n', ...
    numel(head_samples), HEAD_CUTOFF, bcec);

figure;
histogram(head_samples, NBINS_HEAD);
xlabel('Execution cycle');
ylabel('Frequency');
title(sprintf('Head of Distribution (\\leq %d, n = %d, Best-Case = %d)', HEAD_CUTOFF, numel(head_samples), bcec));
grid on;
xline(bcec, 'g', 'LineWidth', 2, 'Label', 'Best-Case');

%% 3. Tail histogram
tail_samples = all_ec.ec(all_ec.ec > TAIL_CUTOFF);

figure;
histogram(tail_samples, NBINS_TAIL);
xlabel('Execution cycle');
ylabel('Frequency');
title(sprintf('Tail of Distribution (> %d, n = %d, Worst-Case = %d)', TAIL_CUTOFF, numel(tail_samples), global_wcec));
grid on;
xline(global_wcec, 'r', 'LineWidth', 2, 'Label', 'Worst-Case');

%% 4. Histograms by scenario
scenarios = unique(all_ec.scenario);

figure;
for i = 1:numel(scenarios)
    sc_name = scenarios{i};
    ec_sc = all_ec.ec(strcmp(all_ec.scenario, sc_name));

    wcec_sc = max(ec_sc);

    subplot(ceil(numel(scenarios)/2), 2, i);
    histogram(ec_sc, 50);

    if LOGARITHMIC_SCALE
        set(gca, 'YScale', 'log');
    end

    xlabel('Execution cycle');
    ylabel('Frequency');
    title(sprintf('%s (Worst-Case = %d)', sc_name, wcec_sc));
    grid on;

    xline(wcec_sc, 'r', 'LineWidth', 2, 'Label', 'Worst-Case');
end
sgtitle('Execution Cycle by Scenario');

%% 5. Histograms by state
state_names = {'Learning','Detecting','Ignoring','Pacing'};
states = unique(all_ec.state);

figure;
for i = 1:numel(states)
    st = states(i);
    ec_st = all_ec.ec(all_ec.state == st);

    wcec_st = max(ec_st);

    subplot(2,2,st+1);
    histogram(ec_st, 50);

    if LOGARITHMIC_SCALE
        set(gca, 'YScale', 'log');
    end

    xlabel('Execution cycle');
    ylabel('Frequency');
    title(sprintf('%s (Worst-Case = %d)', ...
        state_names{st+1}, wcec_st));
    grid on;

    xline(wcec_st, 'r', 'LineWidth', 2, 'Label', 'Worst-Case');
end
sgtitle('Execution Cycle by State');
