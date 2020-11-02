function align_multicolor_to_calcium_imaging(calcium_folder, plot_alignment_figures)
    % align_multicolor_to_calcium_imaging  combines cell location and
    % identification data from a multicolor image analyzed with the
    % NeuroPAL software and links the cell IDs to neurons tracked with the
    % 3dBrain pipeline.
    % I'll use assignments to refer to assigning cells recorded in the
    % multicolor light path to cells recorded in the calcium light path
    % I'll use labels to refer to the cell names (like AVA) identified 
    % with the NeuroPAL software
    
    if nargin < 1
        calcium_folder = [];
    end
    
    if nargin < 2
        % plot some figures showing assignments from calcium to multicolor
        % image
        plot_alignment_figures = true;
    end
    
    % i wrote this to adjust for the fact that different light paths might
    % have different sized images.
    % I tested this on two datasets and it didn't change the assignment
    % accuracy
    normalize_by_distance = false;
    
    %% parameters
    config = get_config();
    
    % stack to align calcium data to
    calcium_index = config.volumes_to_grab{1};
    
    assignment_algorithm = 'nearest';
%     assignment_algorithm = 'hungarian';
    
    %% select brainscanner folder
    if isempty(calcium_folder)
        calcium_folder = uigetdir(config.panneuronal_path, 'Select the brainscanner folder');
        
        if all(calcium_folder == 0)
            return;
        end
    end
    multicolor_search = dir(fullfile(calcium_folder, 'multicolor*'));
    multicolor_search = multicolor_search(1); % take only the first result. Can't handle multiple multicolor folders in one file
    multicolor_folder = fullfile(multicolor_search.folder, multicolor_search.name);

    %% read cell body locations
    calcium_cell_locations = read_cell_locations(fullfile(calcium_folder, 'calcium_data_average_stack_ID.mat'));
    calcium_data = load(fullfile(calcium_folder, 'calcium_data_average_stack.mat'));
    shift_val = calcium_data.shift_val;
    calcium_scale = calcium_data.info.scale;
    calcium_cell_locations = calcium_cell_locations .* calcium_scale';
    calcium_cell_locations = calcium_cell_locations(:, [2, 1, 3]);
    
    [multicolor_cell_locations, multicolor_human_labels, multicolor_auto_labels, user_labeled, auto_confidence] = read_cell_locations(fullfile(multicolor_folder, 'neuropal_data_ID.mat'));
    multicolor_data = load(fullfile(multicolor_folder, 'neuropal_data.mat'));
    multicolor_scale = multicolor_data.info.scale;
    multicolor_cell_locations = multicolor_cell_locations .* multicolor_scale';
    multicolor_cell_locations = multicolor_cell_locations(:, [2, 1, 3]);
    
    %% project the cell body locations into their principal components to deal with flips and permutations
    calcium_cell_location_mean = mean(calcium_cell_locations);
    calcium_cell_locations_meansub = calcium_cell_locations - calcium_cell_location_mean;
    [calcium_cell_locations_pc, calcium_cell_locations_proj] = pca(calcium_cell_locations_meansub);
    
    multicolor_cell_locations_meansub = multicolor_cell_locations - mean(multicolor_cell_locations);
    [~, multicolor_cell_locations_proj] = pca(multicolor_cell_locations_meansub);
    
    if normalize_by_distance
        % normalize to mean minimum distance to another cell
        calcium_dist_to_cells = squeeze(sqrt(sum((calcium_cell_locations_proj - permute(calcium_cell_locations_proj, [3, 2, 1])).^2, 2)));
        calcium_dist_to_cells(logical(eye(size(calcium_dist_to_cells, 1)))) = nan;
        calcium_min_dist_to_cells = nanmin(calcium_dist_to_cells, [], 2);
        calcium_cell_locations_proj = calcium_cell_locations_proj ./ mean(calcium_min_dist_to_cells);

        multicolor_dist_to_cells = squeeze(sqrt(sum((multicolor_cell_locations_proj - permute(multicolor_cell_locations_proj, [3, 2, 1])).^2, 2)));
        multicolor_dist_to_cells(logical(eye(size(multicolor_dist_to_cells, 1)))) = nan;
        multicolor_min_dist_to_cells = nanmin(multicolor_dist_to_cells, [], 2);
        multicolor_cell_locations_proj = multicolor_cell_locations_proj ./ mean(multicolor_min_dist_to_cells);
    end
    
    % calculate skew of the locations and align using that
    calcium_skew = mean(calcium_cell_locations_proj.^3);
    calcium_flip_this_dim = 2*(calcium_skew >= 0) - 1;
    calcium_cell_locations_proj = calcium_cell_locations_proj .* calcium_flip_this_dim;

    multicolor_skew = mean(multicolor_cell_locations_proj.^3);
    multicolor_flip_this_dim = 2*(multicolor_skew >= 0) - 1;
    multicolor_cell_locations_proj = multicolor_cell_locations_proj .* multicolor_flip_this_dim;
    
    %% get tracked cell body locations
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
    % tracked cells location in image space is only saved on a frame by
    % frame basis. Here we create a vector where each entry represents
    % a unique cell whether or not it is in the current frame
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

    % when we flip the image we trim off images in the z stack. adjust the
    % z position here so are cells are not offset.
    if shift_val > 0
        tracked_cell_locations(:, 3) = tracked_cell_locations(:, 3) - shift_val;
    end
    
    % scale calcium data into microns
    tracked_cell_locations = tracked_cell_locations .* calcium_scale';
    
    % subtract the full calcium cell location mean to keep calcium and
    % tracked cells in the same frame. Then project onto the full calcium
    % cell location PCs
    tracked_cell_locations_meansub = tracked_cell_locations - calcium_cell_location_mean;
    tracked_cell_locations_proj = tracked_cell_locations_meansub * calcium_cell_locations_pc;
    tracked_cell_locations_proj = tracked_cell_locations_proj .* calcium_flip_this_dim;
    
    if normalize_by_distance
        tracked_cell_locations_proj = tracked_cell_locations_proj ./ mean(calcium_min_dist_to_cells);
    end 
    
    %% align multicolor and calcium imaging
    [calcium_to_multicolor_assignments, tracked_to_multicolor_assignments] = get_pointcloud_assignments(calcium_cell_locations_proj, multicolor_cell_locations_proj, tracked_cell_locations_proj, assignment_algorithm);

    tracked_to_multicolor_assignments_user_adjusted = tracked_to_multicolor_assignments;
    user_assigned_cells = false(size(tracked_to_multicolor_assignments_user_adjusted));

    rotation = 0;
    flipX = false;
    flipY = false;

    %% plot alignment
    if plot_alignment_figures
        figure;
        scatter3(multicolor_cell_locations_proj(:, 1), multicolor_cell_locations_proj(:, 2), multicolor_cell_locations_proj(:, 3), 'X', 'MarkerEdgeColor', 'r');
        hold on;
        scatter3(calcium_cell_locations_proj(:, 1), calcium_cell_locations_proj(:, 2), calcium_cell_locations_proj(:, 3), 'O', 'MarkerEdgeColor', 'b');
        scatter3(tracked_cell_locations_proj(:, 1), tracked_cell_locations_proj(:, 2), tracked_cell_locations_proj(:, 3), 's', 'MarkerEdgeColor', 'g');

        for aa = 1:length(calcium_to_multicolor_assignments)
            if calcium_to_multicolor_assignments(aa) ~= 0
                x_val = [calcium_cell_locations_proj(aa, 1) multicolor_cell_locations_proj(calcium_to_multicolor_assignments(aa), 1)];
                y_val = [calcium_cell_locations_proj(aa, 2) multicolor_cell_locations_proj(calcium_to_multicolor_assignments(aa), 2)];
                z_val = [calcium_cell_locations_proj(aa, 3) multicolor_cell_locations_proj(calcium_to_multicolor_assignments(aa), 3)];

                plot3(x_val, y_val, z_val, 'k');
            end
        end

        hold off;
        legend({'multicolor', 'calcium', 'tracked calcium'}, 'TextColor', 'black');
        axis equal;
    end
    
    %% link the multicolor labels to the tracked cells
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
    
    %% save the new alignment data
    % save the data that we aligned to
    % the data is small so storing it is not a big deal. This also means
    % that if you run other analysis on the data you can still use this
    % alignment data until you overwrite it.
    heatData = load(fullfile(calcium_folder, 'heatData.mat'));
    output_struct.calcium_data = heatData;
    
    % save the alignment data
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
    output_struct.assignments.rotation = rotation;
    output_struct.assignments.flipX = flipX;
    output_struct.assignments.flipY = flipY;
    
    save(fullfile(calcium_folder, 'calcium_to_multicolor_alignment.mat'), '-struct', 'output_struct');
end