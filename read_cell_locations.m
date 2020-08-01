function [cell_locations, human_labels, auto_labels, user_labeled, auto_confidence] = read_cell_locations(path)
    cell_location_and_id = load(path);
    
    num_cells = length(cell_location_and_id.neurons.neurons);
    cell_locations = zeros(num_cells, 3);
    human_labels = cell(num_cells, 1);
    auto_labels = cell(num_cells, 1);
    user_labeled = false(num_cells, 1);
    auto_confidence = zeros(num_cells, 1);
    
    for cc = 1:num_cells
        this_cell = cell_location_and_id.neurons.neurons(cc);
        cell_locations(cc, :) = this_cell.position;
        human_labels{cc} = this_cell.annotation;
        auto_labels{cc} = this_cell.deterministic_id;
        user_labeled(cc) = this_cell.annotation_confidence == 1;
        auto_confidence(cc) = this_cell.probabilistic_probs(1);
    end
end