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

    referenceData =   lower(referenceData);
    referenceData = replace(referenceData, {'ç', 'ã', 'á', 'à', 'â', 'ê', 'é', 'í', 'î', 'ì', 'ó', 'ò', 'ô', 'õ', 'ú', 'ù', 'û', 'ü'}, ...
                                           {'c', 'a', 'a', 'a', 'a', 'e', 'e', 'i', 'i', 'i', 'o', 'o', 'o', 'o', 'u', 'u', 'u', 'u'});
    referenceData = replace(referenceData, {',', ';', '.', ':', '?', '!', '"', '''', '(', ')', '[', ']', '{', '}'}, ...
                                           {' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '});
    referenceData = strtrim(referenceData);

    switch classData
        case {'cell', 'categorical'}
            uniqueData = unique(referenceData);
            uniqueData(cellfun(@(x) isempty(x), uniqueData)) = [];

        case {'char', 'string'}
            uniqueData = referenceData;
    end
end