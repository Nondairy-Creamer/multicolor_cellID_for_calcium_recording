function align_multicolor_to_calcium_imaging()
    % before running this code, make sure you have extracted calcium traces
    % and cell ID locations. See README
    
    %% parameters
    % multicolor to calcium alignment
    % cell bodies that have no neighbors closer than distance_threshold
    % will be removed, then the cell body locations are aligned again
    % if distance_threshold is empty, the cell body locations will only be
    % registered once without removing any neurons
    distance_threshold = 10;
    
    % stack to align calcium data to
    calcium_index = 100;
    
    % the neuroPAL_alignment can plot some figures showing assignments
    plot_alignment_figures = true;

    assignment_algorithm = 'nearest';
%     assignment_algorithm = 'hungarian';
    
    %% select brainscanner folder
    calcium_folder = uigetdir('/projects/LEIFER/PanNeuronal/', 'Select the brainscanner folder');
    multicolor_search = dir(fullfile(calcium_folder, 'multicolor*'));
    multicolor_folder = fullfile(multicolor_search.folder, multicolor_search.name);
    
%     calcium_folder = '/home/mcreamer/Documents/data_sets/panneuronal/BrainScanner20200130_145049';
%     multicolor_folder = '/home/mcreamer/Documents/data_sets/neuropal/creamer/20200130/multicolorworm_20200130_145049';
%     
    %% read cell body locations
    calcium_in = readmatrix(fullfile(calcium_folder, 'calcium_data_average_stack.csv'));
    calcium_cell_locations = calcium_in(:, 6:8);
    
    neuropal_output_path = fullfile(multicolor_folder, 'neuropal_data.csv');
    multicolor_in = readmatrix(neuropal_output_path);
    multicolor_cell_locations = multicolor_in(:, 6:8);
    multicolor_cell_locations_permuted = multicolor_cell_locations(:, [2, 1, 3]);
    multicolor_cell_locations_permuted(:, 2) = -multicolor_cell_locations_permuted(:, 2);
    multicolor_data = load(fullfile(multicolor_folder, 'neuropal_data.mat'));
    multicolor_scale = multicolor_data.info.scale;
    
    % save label information
    multicolor_human_labels = readmatrix(neuropal_output_path, 'OutputType', 'char', 'Range', 'A:A');
    multicolor_auto_labels = readmatrix(neuropal_output_path, 'OutputType', 'char', 'Range', 'C:C');

    neuropal_in = readmatrix(neuropal_output_path);
    user_labeled = neuropal_in(:, 2)  == 1;
    auto_confidence = neuropal_in(:, 4);
    
    %% get tracked cell body locations
    calcium_stack = load(fullfile(calcium_folder, 'calcium_data_average_stack.mat'));
    calcium_scale = calcium_stack.info.scale;
    tracked_cell_locations_in = load(fullfile(calcium_folder, 'PointsStats2.mat'));
    tracked_cell_locations_in = tracked_cell_locations_in.pointStats2;
    num_tracked_cells = 0;
    
    % get number of tracked cells
    for tt = 1:length(tracked_cell_locations_in)
        if max(tracked_cell_locations_in(tt).trackIdx) > num_tracked_cells
            num_tracked_cells = max(tracked_cell_locations_in(tt).trackIdx);
        end
    end
    
    % create full array of tracked cell locations
    tracked_cell_locations = nan(num_tracked_cells, 3);
    t_loc = calcium_index;
    while any(isnan(tracked_cell_locations(:)))
        cell_id_at_t = tracked_cell_locations_in(t_loc).trackIdx;
        
        for cc = 1:length(cell_id_at_t)
            this_cell = cell_id_at_t(cc);
            if ~any(isnan(this_cell))
                if any(isnan(tracked_cell_locations(this_cell)))
                    tracked_cell_locations(cell_id_at_t(cc), :) = tracked_cell_locations_in(t_loc).rawPoints(cc, :);
                end
            end
        end
        
        t_loc = t_loc + 1;
    end
    
    % scale calcium data into microns
    tracked_cell_locations = tracked_cell_locations .* calcium_scale';
 
    %% align multicolor and calcium imaging
    save_path = calcium_folder;
    [calcium_to_multicolor_assignments, tracked_to_multicolor_assignments, multicolor_rotated] = get_pointcloud_assignments(calcium_cell_locations, multicolor_cell_locations_permuted, tracked_cell_locations, assignment_algorithm, distance_threshold);
    
    tracked_human_labels = cell(length(tracked_to_multicolor_assignments), 1);
    tracked_auto_labels = cell(length(tracked_to_multicolor_assignments), 1);
    for cc = 1:length(tracked_to_multicolor_assignments)
        if tracked_to_multicolor_assignments(cc) ~= 0
            tracked_human_labels{cc} = multicolor_human_labels{tracked_to_multicolor_assignments(cc)};
            tracked_auto_labels{cc} = multicolor_auto_labels{tracked_to_multicolor_assignments(cc)};
        else
            tracked_human_labels{cc} = '';
            tracked_auto_labels{cc} = '';
        end
    end
    
    [~, sort_ids] = sort(tracked_cell_locations(:, 3), 1, 'ascend');
    tracked_cell_locations = tracked_cell_locations(sort_ids, :);
    tracked_to_multicolor_assignments = tracked_to_multicolor_assignments(sort_ids, :);
    tracked_to_multicolor_assignments_user_adjusted = tracked_to_multicolor_assignments;
    user_assigned_cells = false(size(tracked_to_multicolor_assignments_user_adjusted));
    
    % get the associated calcium data
    calcium_recording = load(fullfile(calcium_folder, 'heatData.mat'));
    output_struct.calcium_recording.data = calcium_recording.Ratio2;
    output_struct.calcium_recording.time = calcium_recording.hasPointsTime;
    
    output_struct.labels.tracked_human_labels = tracked_human_labels;
    output_struct.labels.tracked_auto_labels = tracked_auto_labels;
    output_struct.labels.multicolor_human_labels = multicolor_human_labels;
    output_struct.labels.multicolor_auto_labels = multicolor_auto_labels;
    output_struct.labels.user_labeled = user_labeled;
    output_struct.labels.auto_confidence = auto_confidence;
    
    output_struct.locations.multicolor_scale = multicolor_scale;
    output_struct.locations.calcium_scale = calcium_scale;
    output_struct.locations.calcium_cell_locations = calcium_cell_locations;
    output_struct.locations.multicolor_cell_locations = multicolor_cell_locations;
    output_struct.locations.tracked_cell_locations = tracked_cell_locations;
    
    output_struct.assignments.calcium_to_multicolor_assignments = calcium_to_multicolor_assignments;
    output_struct.assignments.tracked_to_multicolor_assignments = tracked_to_multicolor_assignments;
    output_struct.assignments.tracked_to_multicolor_assignments_user_adjusted = tracked_to_multicolor_assignments_user_adjusted;
    output_struct.assignments.user_assigned_cells = user_assigned_cells;
    output_struct.assignments.rotation = 0;
    output_struct.assignments.flipX = false;
    output_struct.assignments.flipY = false;
    
    save(fullfile(save_path, 'calcium_to_multicolor_alignment.mat'), '-struct', 'output_struct');
    
    %% plot alignment
    if plot_alignment_figures
        % plot histogram of distances between assigned pairs
%         MakeFigure;
%         histogram(assignment_distance(assignment_distance ~= -1), 50);

        figure;
        scatter3(multicolor_rotated(:, 1), multicolor_rotated(:, 2), multicolor_rotated(:, 3), 'X', 'MarkerEdgeColor', 'r');
        hold on;
        scatter3(calcium_cell_locations(:, 1), calcium_cell_locations(:, 2), calcium_cell_locations(:, 3), 'O', 'MarkerEdgeColor', 'b');
        scatter3(tracked_cell_locations(:, 1), tracked_cell_locations(:, 2), tracked_cell_locations(:, 3), 's', 'MarkerEdgeColor', 'g');

        for aa = 1:length(calcium_to_multicolor_assignments)
            if calcium_to_multicolor_assignments(aa) ~= 0
                x_val = [calcium_cell_locations(aa, 1) multicolor_rotated(calcium_to_multicolor_assignments(aa), 1)];
                y_val = [calcium_cell_locations(aa, 2) multicolor_rotated(calcium_to_multicolor_assignments(aa), 2)];
                z_val = [calcium_cell_locations(aa, 3) multicolor_rotated(calcium_to_multicolor_assignments(aa), 3)];

                plot3(x_val, y_val, z_val, 'k');
            end
        end

        hold off;
        legend({'adjusted cloud', 'fixed cloud'}, 'TextColor', 'black');
        axis equal;
    end
end