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
    
    % after identities linking multicolor to calcium data, we remove links
    % that are too far apart from 
    max_allowed_assignment_distance = 10;
    
    % the neuroPAL_alignment can plot some figures showing assignments
    plot_alignment_figures = true;

    assignment_algorithm = 'nearest';
%     assignment_algorithm = 'hungarian';
    
    %% select brainscanner folder
    calcium_folder = uigetdir('/projects/LEIFER/PanNeuronal/', 'select the brainscanner folder');
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
    
    calcium_stack = load(fullfile(calcium_folder, 'calcium_data_average_stack.mat'));
    tracked_neurons = load(fullfile(calcium_folder, 'pointStatsNew'));
    tracked_neurons = tracked_neurons.pointStatsNew(calcium_index).rawPoints .* calcium_stack.info.scale';
    
    %% align multicolor and calcium imaging
    save_path = calcium_folder;
    [assignments, multicolor_rotated, assignment_distance] = get_pointcloud_assignments(calcium_cell_locations, multicolor_cell_locations_permuted, tracked_neurons, assignment_algorithm, distance_threshold, max_allowed_assignment_distance);

    save(fullfile(save_path, 'calcium_to_neuropal_alignment.mat'), 'calcium_cell_locations', 'multicolor_cell_locations', 'assignments');
        
    %% plot alignment    
    if plot_alignment_figures
        % plot histogram of distances between assigned pairs
        MakeFigure;
        histogram(assignment_distance(assignment_distance ~= -1), 50);

        MakeFigure;
        scatter3(multicolor_rotated(:, 1), multicolor_rotated(:, 2), multicolor_rotated(:, 3), 'X', 'MarkerEdgeColor', 'r');
        hold on;
        scatter3(calcium_cell_locations(:, 1), calcium_cell_locations(:, 2), calcium_cell_locations(:, 3), 'O', 'MarkerEdgeColor', 'b');

        for aa = 1:length(assignments)
            if assignments(aa) ~= 0
                x_val = [calcium_cell_locations(aa, 1) multicolor_rotated(assignments(aa), 1)];
                y_val = [calcium_cell_locations(aa, 2) multicolor_rotated(assignments(aa), 2)];
                z_val = [calcium_cell_locations(aa, 3) multicolor_rotated(assignments(aa), 3)];

                plot3(x_val, y_val, z_val, 'k');
            end
        end

        hold off;
        legend({'adjusted cloud', 'fixed cloud'}, 'TextColor', 'black');
        axis equal;
    end
end