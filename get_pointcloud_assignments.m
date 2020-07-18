function [multicolor_assignments, tracked_assignments, adjusted_rotated] = get_pointcloud_assignments(fixed_points, adjusted_points, tracked_points, assignment_algorithm, distance_threshold)
    % _r means it was registered with cpd rigid
    % _nr means it was registered with cpd nonrigid
    % _o means outliers were removed

    if nargin < 5
        distance_threshold = [];
    end
    
    if isempty(distance_threshold)
        remove_outliers = false;
    else
        remove_outliers = true;
    end
    
    fixed_cloud = pointCloud(fixed_points);
    adjusted_cloud = pointCloud(adjusted_points);
    
    [~, adjusted_cloud_r] = pcregistercpd(adjusted_cloud, fixed_cloud, 'Transform', 'Rigid');

    adjusted_rotated = adjusted_cloud_r.Location;
%     [~, adjusted_cloud_r_nr] = pcregistercpd(adjusted_cloud_r, fixed_cloud, 'Transform', 'NonRigid');
    adjusted_cloud_r_nr = adjusted_cloud_r;
    
    %% Remove points that have no nearby neighbors
    fixed_points_to_keep = true(size(fixed_points, 1), 1);
    adjusted_points_to_keep = true(size(adjusted_points, 1), 1);
    
    if remove_outliers
        fixed_to_adjusted_distance = get_point_cloud_distance(fixed_cloud.Location, adjusted_cloud_r_nr.Location);
        fixed_to_adjusted_min_distance = min(fixed_to_adjusted_distance, [], 2);
        adjusted_to_fixed_min_distance = min(fixed_to_adjusted_distance, [], 1)';

        fixed_points_to_keep = fixed_to_adjusted_min_distance < distance_threshold;
        adjusted_points_to_keep = adjusted_to_fixed_min_distance < distance_threshold;
        
        fixed_points_o = fixed_points(fixed_points_to_keep, :);
        adjusted_points_r_nr_o = adjusted_cloud_r_nr.Location(adjusted_points_to_keep, :);

        fixed_cloud_o = pointCloud(fixed_points_o);
        adjusted_cloud_r_nr_o = pointCloud(adjusted_points_r_nr_o);

        [~, adjusted_cloud_r_nr_o_r] = pcregistercpd(adjusted_cloud_r_nr_o, fixed_cloud_o, 'Transform', 'Rigid');
        [~, adjusted_cloud_r_nr_o_r_nr] = pcregistercpd(adjusted_cloud_r_nr_o_r, fixed_cloud_o, 'Transform', 'NonRigid');
    else
        fixed_cloud_o = fixed_cloud;
        adjusted_cloud_r_nr_o_r_nr = adjusted_cloud_r_nr;
    end
        
    %% assign IDs
    fixed_to_adjusted_distance = get_point_cloud_distance(fixed_cloud_o.Location, adjusted_cloud_r_nr_o_r_nr.Location);
    tracked_to_adjusted_distance = get_point_cloud_distance(tracked_points, adjusted_cloud_r_nr_o_r_nr.Location);

    switch assignment_algorithm
        case 'hungarian'
            [multicolor_assignment_raw, ~] = munkres(fixed_to_adjusted_distance);
            multicolor_assignment_raw = multicolor_assignment_raw';
            [tracked_assignment_raw, ~] = munkres(tracked_to_adjusted_distance);
            tracked_assignment_raw = tracked_assignment_raw';
        
        case 'nearest'
            multicolor_assignment_raw = nearest_neighbor_assignment(fixed_to_adjusted_distance);
            tracked_assignment_raw = nearest_neighbor_assignment(tracked_to_adjusted_distance);
    end
    
    % assignment IDs are in the order of the vector with outliers removed
    % get assignments IDs where outliers weren't removed
    multicolor_assignments = zeros(size(fixed_points, 1), 1);
    tracked_assignments = zeros(size(tracked_points, 1), 1);
    
    for aa = 1:length(multicolor_assignment_raw)
        if multicolor_assignment_raw(aa) ~= 0
            orig_fixed_index = find(fixed_points_to_keep, aa);

            orig_fixed_index = orig_fixed_index(end);

            orig_adjusted_index = find(adjusted_points_to_keep, multicolor_assignment_raw(aa));
            orig_adjuisted_index = orig_adjusted_index(end);

            multicolor_assignments(orig_fixed_index) = orig_adjuisted_index;
        end
    end
    
    for tt = 1:length(tracked_assignment_raw)
        if tracked_assignment_raw(tt) ~= 0
            orig_adjusted_index = find(adjusted_points_to_keep, tracked_assignment_raw(tt));
            orig_adjuisted_index = orig_adjusted_index(end);

            tracked_assignments(tt) = orig_adjuisted_index;
        end
    end
end

function cloud1_to_cloud2_distance = get_point_cloud_distance(cloud1, cloud2)
    cloud1_to_cloud2_distance = cloud1 - permute(cloud2, [3, 2, 1]);
    cloud1_to_cloud2_distance = squeeze(sqrt(sum(cloud1_to_cloud2_distance.^2, 2)));
end

function assignment = nearest_neighbor_assignment(fixed_to_adjusted_distance)
    [~, fixed_to_adjusted_nearest_id] = min(fixed_to_adjusted_distance, [], 2);
    [~, adjusted_to_fixed_nearest_id] = min(fixed_to_adjusted_distance, [], 1);

    assignment = zeros(size(fixed_to_adjusted_distance, 1), 1);

    for aa = 1:length(assignment)
        fixed_assignment = fixed_to_adjusted_nearest_id(aa);
        adjusted_assignment = adjusted_to_fixed_nearest_id(fixed_assignment);

        if adjusted_assignment == aa
            assignment(aa) = fixed_assignment;
        end
    end
end