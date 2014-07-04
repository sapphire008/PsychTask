function ParseData(path,subjectID,aratings,vratings,circles)


    cd(path.data)

    filename = [num2str(subjectID) '_ratings.csv'];
    
    data = {};
    
    header = {'gamble','arousal','valence'};
    
    for i = 1:length(header)
        data{1,i} = header{i};
    end
    
    for i = 1:length(aratings)
        arousal = num2str(aratings(i));
        valence = num2str(vratings(i));
        gamble = circles{i};
        
        row = {gamble,arousal,valence};
        
        for j = 1:length(row)
            data{i+1,j} = row{j};
        end
        
    end
        
    cell2csv(filename,data,',',1999);
    
    cd(path.main)

end