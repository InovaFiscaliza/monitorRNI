function [uniqueData, referenceData] = PreProcessedData(rawData)

    classData = class(rawData);
    switch classData
        case 'cell'
            referenceData = rawData;
        case 'categorical'
            referenceData = cellstr(rawData);
        case {'char', 'string'}
            referenceData = char(rawData);
        otherwise
            error('Unexpected datatype')
    end
  
    referenceData = textAnalysis.normalizeWords(referenceData);
    referenceData = replace(referenceData, {',', ';', '.', ':', '?', '!', '"', '''', '(', ')', '[', ']', '{', '}'}, ...
                                           {' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '});
    referenceData = strtrim(referenceData);

    switch classData
        case {'cell', 'categorical'}
            uniqueData = unique(referenceData, 'stable');
            uniqueData(cellfun(@(x) isempty(x), uniqueData)) = [];

        case {'char', 'string'}
            uniqueData = referenceData;
    end
end