function neuroPAL_check_alignment()
    %% load assignment data
    alignment = load('/home/mcreamer/Documents/aligned_data/align_data.mat');
    
    %% load the fixed data
    fixed_folder = '/home/mcreamer/Documents/fake_aml/20200130/first_2_sec';

    fixed_paths = dir(fullfile(fixed_folder, 'chunk_*.mat'));
    num_chunks = length(fixed_paths);

    fixed_in = cell(num_chunks, 1);

    for cc = 1:num_chunks
        fixed_in{cc} = load(fullfile(fixed_folder, fixed_paths(cc).name));
        fixed_in{cc} = fixed_in{cc}.red(:, :, 1:32);
    end

    fixed_image = fixed_in{1};

    for dd = 2:num_chunks
        fixed_image = fixed_image + fixed_in{dd};
    end

    fixed_image = fixed_image / num_chunks;
    
    %% load the data to align
    align_folder = '/home/mcreamer/Documents/fake_aml/20200130/last_2_sec';

    align_paths = dir(fullfile(align_folder, 'chunk_*.mat'));
    num_chunks = length(align_paths);

    align_in = cell(num_chunks, 1);

    for cc = 1:num_chunks
        align_in{cc} = load(fullfile(align_folder, align_paths(cc).name));
        align_in{cc} = align_in{cc}.red(:, :, 1:32);
    end

    align_image = align_in{1};

    for dd = 2:num_chunks
        align_image = align_image + align_in{dd};
    end

    align_image = align_image / num_chunks;
    
    %% plot the stacks side by side
    MakeFigure;
    subplot(1,2,1);
end