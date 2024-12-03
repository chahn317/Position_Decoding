%% Author: Christina Hahn

%% User inputs (Modify as necessary)

folder = pwd; % Current directory
raw_data_folder = './Raw_Data/'; % Directory where kinematics/neural data is being stored
results_folder = './Data_Formatted'; % Directory to store formatted results

% Marker regions
marker_regions = {'Anterior', 'Intermediate', 'Posterior', 'Superficial', 'Deep'};

%% Organize raw data files

files = {dir(raw_data_folder).name};
data_map = containers.Map;

for i = 1:length(files)
    if contains(files{i}, 'Kinematics')
        kin_split = split(files{i}, '_');
        dataset = kin_split{1};
        for j = 1:length(files)
            neural_split = split(files{j}, '_');
            if strcmp(neural_split{1}, dataset) & contains(files{j}, 'sortedspikes')
                if ~isKey(data_map, dataset)
                    data_map(dataset) = {};
                end
                data_map(dataset) = cat(1, data_map(dataset), neural_split{2});
            end
        end
    end
end

%% Generate formatted data

% Create directory to save results
mkdir(results_folder);

datasets = data_map.keys;
for i = 1:length(datasets)
    dataset = char(datasets(i));
    kinematics = load(strcat(raw_data_folder, dataset, '_Kinematics.mat'));

    neural_regions = data_map(dataset);
    for j = 1:length(neural_regions)
        neural_region = char(neural_regions(j));

        % Get correct spike data format
        sorted_spikes = load(strcat(raw_data_folder, dataset, '_', neural_region, '_sortedspikes.mat'));
        neurons = fieldnames(sorted_spikes);
        if length(neurons) == 1
            test_file = sorted_spikes.(neurons{1});
            test_fields = fieldnames(test_file);
            if ~ismember('times', test_fields)
                sorted_spikes = test_file;
                neurons = test_fields;
            end
        end

        for k = 1:length(marker_regions)
            marker_region = marker_regions{k};
            fprintf('Processing %s_%s_%s...\n', dataset, neural_region, marker_region)

            % Get markers
            column_names = kinematics.Kinematics.ColumnNames.points;
            marker_indices = find(contains(column_names, marker_region) & ~contains(column_names, 'Lateral'));
            markers = column_names(marker_indices);

            output_times = [];
            outputs = [];
            neuralIdx = kinematics.Kinematics.NeuralIndex;
            output_data = kinematics.Kinematics.Cranium.points;
            spikes = cell([length(neurons), 1]);

            for l = 1:length(neuralIdx)
                % Keep only rows with no NaNs
                keep = output_data{l, 1}(:, marker_indices);
                tf = sum(isnan(keep), 2) == 0 & sum(isnan(neuralIdx{l, 1}), 2) == 0;
                if (~any(tf))
                    continue
                end

                % Real start/end times for each trial
                notNans_times = neuralIdx{l, 1}(tf, 3);
                neural_start = notNans_times(1, 1);
                neural_end = notNans_times(length(notNans_times), 1);

                % Set start times to be continuous
                if l == 1
                    start_time = neural_start;
                else
                    start_time = output_times(length(output_times)) + 0.005;
                end

                % Process outputs/output times
                notNans_output = keep(tf, :);
                outputs = cat(1, outputs, notNans_output);
                notNans_times = transpose(start_time:0.005:start_time + 0.005 * (length(notNans_output) - 1));
                output_times = cat(1, output_times, notNans_times);

                % Process spike times
                for m = 1:length(neurons)
                    neuron = neurons{m};
                    spike_times = sorted_spikes.(neuron).times;
                    tf = spike_times > neural_start & spike_times < neural_end;
                    time_diff = neural_start - start_time;
                    temp = spike_times(tf) - time_diff;
                    spikes{m, 1} = cat(1, spikes{m, 1}, temp);
                end
            end

            spikes = spikes(~cellfun('isempty',spikes)); % Remove empty neurons

            % Save results
            parent = cd(results_folder);
            save(strcat(dataset, "_", neural_region, "_", marker_region, ".mat"), 'spikes', 'output_times', 'outputs', 'markers');
            cd(parent);
        end
    end
end

