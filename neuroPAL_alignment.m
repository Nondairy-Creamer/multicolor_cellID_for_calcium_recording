function neuroPAL_alignment(fixed_points, adjusted_points, save_path, distance_threshold, max_allowed_assignment_distance, plot_alignment_figures)
    
    if nargin < 4
        distance_threshold = 3;
    end
    
    if nargin < 5
        max_allowed_assignment_distance = 5;
    end
    
    if nargin < 6
        plot_alignment_figures = false;
    end
    
    if isempty(distance_threshold)
        remove_outliers = false;
    else
        remove_outliers = true;
    end
    
    fixed_initial = fixed_points;
    adjusted_initial = adjusted_points;

    fixed_cloud = pointCloud(fixed_points);
    adjusted_cloud = pointCloud(adjusted_points);

    [~, adjusted_cloud_registered] = pcregistercpd(adjusted_cloud, fixed_cloud, 'Transform', 'Rigid');
    fixed_rotated = fixed_cloud.Location;
    adjusted_rotated = adjusted_cloud_registered.Location;
    [~, adjusted_cloud_registered] = pcregistercpd(adjusted_cloud_registered, fixed_cloud, 'Transform', 'NonRigid');
    
    fixed_points_to_keep = true(size(fixed_points, 1), 1);
    adjusted_points_to_keep = true(size(adjusted_points, 1), 1);
    
    %% calculate minimum distance
    if remove_outliers
        fixed_to_adjusted_distance = fixed_cloud.Location - permute(adjusted_cloud_registered.Location, [3, 2, 1]);
        fixed_to_adjusted_distance = squeeze(sqrt(sum(fixed_to_adjusted_distance.^2, 2)));
        fixed_to_adjusted_min_distance = min(fixed_to_adjusted_distance, [], 2);
        adjusted_to_fixed_min_distance = squeeze(min(fixed_to_adjusted_distance, [], 1));

        fixed_points_to_keep =  fixed_to_adjusted_min_distance < distance_threshold;
        adjusted_points_to_keep = adjusted_to_fixed_min_distance < distance_threshold;
        
        fixed_points = fixed_points(fixed_points_to_keep, :);
        adjusted_points = adjusted_cloud_registered.Location(adjusted_points_to_keep, :);

        fixed_cloud = pointCloud(fixed_points);
        adjusted_cloud_registered = pointCloud(adjusted_points);

        [~, adjusted_cloud_registered] = pcregistercpd(adjusted_cloud_registered, fixed_cloud, 'Transform', 'Rigid');
        [~, adjusted_cloud_registered] = pcregistercpd(adjusted_cloud_registered, fixed_cloud, 'Transform', 'NonRigid');
    end

    fixed_to_adjusted_distance = fixed_cloud.Location - permute(adjusted_cloud_registered.Location, [3, 2, 1]);
    fixed_to_adjusted_distance = squeeze(sqrt(sum(fixed_to_adjusted_distance.^2, 2)));
        
    %% assign IDs
    [assignment, cost] = munkres(fixed_to_adjusted_distance);
    assignment = assignment';
    
    % take the assignments and convert the indicies to the original vector
    % before we removed any points
    new_assignments = zeros(size(fixed_initial, 1), 1);
    
    for aa = 1:length(assignment)
        if (assignment(aa) ~= 0)
            orig_fixed_index = find(fixed_points_to_keep, aa);

            orig_fixed_index = orig_fixed_index(end);

            orig_adjusted_index = find(adjusted_points_to_keep, assignment(aa));
            orig_adjuisted_index = orig_adjusted_index(end);

            new_assignments(orig_fixed_index) = orig_adjuisted_index;
        end
    end
    
    %% calculate assignment distance
    assignment_distance = zeros(size(fixed_rotated, 1), 1) - 1;
    
    for ii = 1:size(fixed_rotated, 1)
        if new_assignments(ii) ~= 0
            assignment_distance(ii) = sqrt(sum((fixed_rotated(ii, :) - adjusted_rotated(new_assignments(ii), :)).^2));
        end
    end
    
    new_assignments(assignment_distance > max_allowed_assignment_distance) = 0;
    assignment_distance(assignment_distance > max_allowed_assignment_distance) = -1;
    
    save(fullfile(save_path, 'calcium_to_neuropal_alignment.mat'), 'fixed_initial', 'adjusted_initial', 'new_assignments');
    
    %% plotting
    
    if plot_alignment_figures
        MakeFigure;
        histogram(assignment_distance(assignment_distance ~= -1), 50);

        MakeFigure;
        pcshowpair(adjusted_cloud, fixed_cloud,'MarkerSize',50);
        legend({'adjusted cloud', 'fixed cloud'}, 'TextColor', 'white');
        axis equal;

        MakeFigure;
    %     pcshowpair(adjusted_cloud_registered, fixed_cloud,'MarkerSize',50);
        scatter3(adjusted_cloud_registered.Location(:, 1), adjusted_cloud_registered.Location(:, 2), adjusted_cloud_registered.Location(:, 3), 'X', 'MarkerEdgeColor', 'r');
        hold on;
        scatter3(fixed_cloud.Location(:, 1), fixed_cloud.Location(:, 2), fixed_cloud.Location(:, 3), 'O', 'MarkerEdgeColor', 'b');
        hold off;
        legend({'adjusted cloud', 'fixed cloud'}, 'TextColor', 'black');
        axis equal;

        MakeFigure;
        scatter3(adjusted_rotated(:, 1), adjusted_rotated(:, 2), adjusted_rotated(:, 3), 'X', 'MarkerEdgeColor', 'r');
        hold on;
        scatter3(fixed_rotated(:, 1), fixed_rotated(:, 2), fixed_rotated(:, 3), 'O', 'MarkerEdgeColor', 'b');

        for aa = 1:length(new_assignments)
            if new_assignments(aa) ~= 0
                x_val = [fixed_rotated(aa, 1) adjusted_rotated(new_assignments(aa), 1)];
                y_val = [fixed_rotated(aa, 2) adjusted_rotated(new_assignments(aa), 2)];
                z_val = [fixed_rotated(aa, 3) adjusted_rotated(new_assignments(aa), 3)];

                plot3(x_val, y_val, z_val, 'k');
            end
        end

        hold off;
        legend({'adjusted cloud', 'fixed cloud'}, 'TextColor', 'black');
        axis equal;
    end
end