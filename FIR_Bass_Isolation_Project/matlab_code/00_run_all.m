%% 00_run_all.m
% Master runner -- executes every project script in sequence.
% Aborts immediately if the dependency check or any script fails.

fprintf('============================================\n');
fprintf('  FIR Bass Isolation -- Full Pipeline Run\n');
fprintf('============================================\n\n');

tTotal = tic;

%% Step 0: Dependency check
fprintf('>>> Running dependency check ...\n');
run('00_check_dependencies.m');
fprintf('\n');

%% Step 1: Preprocessing
fprintf('>>> 01 -- Preprocessing audio ...\n');
run('01_preprocess_audio.m');
fprintf('\n');

%% Step 2: Baseline analysis of original audio
fprintf('>>> 02 -- Analyzing original audio ...\n');
run('02_analyze_original_audio.m');
fprintf('\n');

%% Step 3: Filter design
fprintf('>>> 03 -- Designing filters ...\n');
run('03_design_filters.m');
fprintf('\n');

%% Step 4: Filter evaluation
fprintf('>>> 04 -- Evaluating filters ...\n');
run('04_evaluate_filters.m');
fprintf('\n');

%% Step 5: Apply filters
fprintf('>>> 05 -- Applying filters ...\n');
run('05_apply_filters.m');
fprintf('\n');

%% Step 6: Post-filter comparison
fprintf('>>> 06 -- Comparing results ...\n');
run('06_compare_results.m');
fprintf('\n');

%% Step 7: Selection and summary
fprintf('>>> 07 -- Selecting best design and summarizing ...\n');
run('07_select_best_and_summarize.m');
fprintf('\n');

elapsed = toc(tTotal);
fprintf('============================================\n');
fprintf('  Pipeline complete in %.1f seconds (%.1f min)\n', elapsed, elapsed/60);
fprintf('============================================\n');
