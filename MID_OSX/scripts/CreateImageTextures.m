% CreateImageTextures does exactly what it sounds like. It goes into the
% images folder, looks for images by name in the cellarray image_names, and
% then converts those images to preloaded Psychtoolbox textures for speedy
% presentation:

function textures = CreateImageTextures(Window,filepath,image_names)

    % Go into the images folder:
    cd(filepath.images)
    
    % Initialize the textures cellarray that will be returned:
    textures = {};
    
    % Iterate through the names and convert the images to textures; load
    % them into the return cellarray:
    for i = 1:length(image_names)
        name = [image_names{i} '.bmp'];
        img = imread(name);
        tex = Screen('MakeTexture',Window,img);
        textures{i} = tex;
    end
    
    % Go back into the scripts folder:
    cd(filepath.scripts)

end