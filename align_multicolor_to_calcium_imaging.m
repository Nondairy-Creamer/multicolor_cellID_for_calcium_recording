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
    
    multicolor_in = readmatrix(fullfile(multicolor_folder, 'neuropal_data.csv'));
    multicolor_cell_locations = multicolor_in(:, 6:8);
    multicolor_cell_locations_permuted = multicolor_cell_locations(:, [2, 1, 3]);
    multicolor_cell_locations_permuted(:, 2) = -multicolor_cell_locations_permuted(:, 2);
    multicolor_data = load(fullfile(multicolor_folder, 'neuropal_data.mat'));
    multicolor_scale = multicolor_data.info.scale;
    
    calcium_stack = load(fullfile(calcium_folder, 'calcium_data_average_stack.mat'));
    calcium_scale = calcium_stack.info.scale;
    tracked_cell_locations = load(fullfile(calcium_folder, 'pointStatsNew'));
    tracked_cell_locations = tracked_cell_locations.pointStatsNew(calcium_index).rawPoints .* calcium_scale';
    
    %% align multicolor and calcium imaging
    save_path = calcium_folder;
    [calcium_to_multicolor_assignments, tracked_to_multicolor_assignments, multicolor_rotated] = get_pointcloud_assignments(calcium_cell_locations, multicolor_cell_locations_permuted, tracked_cell_locations, assignment_algorithm, distance_threshold);
    
    [~, sort_ids] = sort(tracked_cell_locations(:, 3), 1, 'ascend');
    tracked_cell_locations = tracked_cell_locations(sort_ids, :);
    tracked_to_multicolor_assignments = tracked_to_multicolor_assignments(sort_ids, :);
    tracked_to_multicolor_assignments_user_adjusted = tracked_to_multicolor_assignments;
    user_labeled_cells = false(size(tracked_to_multicolor_assignments_user_adjusted));
    
    output_struct.multicolor_scale = multicolor_scale;
    output_struct.calcium_scale = calcium_scale;
    output_struct.calcium_cell_locations = calcium_cell_locations;
    output_struct.multicolor_cell_locations = multicolor_cell_locations;
    output_struct.tracked_cell_locations = tracked_cell_locations;
    output_struct.calcium_to_multicolor_assignments = calcium_to_multicolor_assignments;
    output_struct.tracked_to_multicolor_assignments = tracked_to_multicolor_assignments;
    output_struct.tracked_to_multicolor_assignments_user_adjusted = tracked_to_multicolor_assignments_user_adjusted;
    output_struct.user_labeled_cells = user_labeled_cells;
    output_struct.rotation = 0;
    output_struct.flipX = false;
    output_struct.flipY = false;
    
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