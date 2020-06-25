function neuropal_input = get_default_neuropal_input(data, path)
    neuropal_input.data = data;

    neuropal_input.info.file = path;
    neuropal_input.info.scale = 1e-3*[420, 420, 1666]';
    neuropal_input.info.DIC = 2;
    neuropal_input.info.RGBW = [5, 3, 1, 4]';
    neuropal_input.info.GFP = 2;
    neuropal_input.info.gamma = 1;

    neuropal_input.prefs.RGBW = [5, 3, 1, 4]';
    neuropal_input.prefs.DIC = 2;
    neuropal_input.prefs.GFP = 2;
    neuropal_input.prefs.gamma = 1; %app.gamma_val;
    neuropal_input.prefs.rotate.horizontal = false;
    neuropal_input.prefs.rotate.vertical = false;
    neuropal_input.prefs.z_center = round(size(data, 3)/2);
    neuropal_input.prefs.is_Z_LR = true;            
    neuropal_input.prefs.is_Z_flip = false;            

    neuropal_input.version = 1.1;

    neuropal_input.worm.body = 'Head';
    neuropal_input.worm.age = 'Adult';
    neuropal_input.worm.sex = 'XX';
    neuropal_input.worm.strain = '';
    neuropal_input.worm.notes = '';
end