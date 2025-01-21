function [stationTable, rawListOfYears, refListOfLocations, refListOfStates] = MonitoringPlan(appName, rootFolder, appGeneral)
    
    [projectFolder, ...
     programDataFolder] = appUtil.Path(appName, rootFolder);

    projectFilePath     = fullfile(projectFolder,     appGeneral.MonitoringPlan.ReferenceFile);
    programDataFilePath = fullfile(programDataFolder, appGeneral.MonitoringPlan.ReferenceFile);

    if isfile(programDataFilePath)
        stationTable = readtable(programDataFilePath, 'VariableNamingRule', 'preserve');
    else
        stationTable = readtable(projectFilePath,     'VariableNamingRule', 'preserve');
    end

    % Dados inválidos (Coordenada geográficas):
    idxInvalid = isnan(stationTable.Lat) | isnan(stationTable.Long);
    if any(idxInvalid)
        stationTable(idxInvalid, :)       = [];
    end

    % Filtro por ano:
    rawListOfYears = unique(stationTable.Ano);
    idxFilter = ~ismember(stationTable.Ano, appGeneral.MonitoringPlan.Period);
    if any(idxFilter)
        stationTable(idxFilter, :)        = [];
    end
    
    % Conversões:
    stationTable.Fistel                   = uint64(stationTable.Fistel);
    stationTable.("N° estacao")           = uint32(stationTable.("N° estacao"));

    % Dados inválidos (Duplicados por possuírem mesmos valores p/ colunas 
    % "Fistel", "Nº estação", "Lat" e "Long"):
    strHashBase = cellstr(string(stationTable.Fistel) + "; " + string(stationTable.("N° estacao")) + "; " + string(stationTable.Lat) + "; " + string(stationTable.Long));
    stationTable.Base64Hash               = cellfun(@(x) Base64Hash.encode(x), strHashBase, 'UniformOutput', false);
    [~, idxUnique] = unique(stationTable.Base64Hash, 'stable');
    stationTable = stationTable(idxUnique, :);
    
    % Novas colunas:
    stationTable.Location                 = strcat(stationTable.("Município"), '/', stationTable.UF);
    stationTable.Latitude                 = stationTable.Lat;
    stationTable.Longitude                = stationTable.Long;
    
    stationTable.numberOfMeasures(:)      = 0;
    stationTable.numberOfRiskMeasures(:)  = 0;
    stationTable.minDistanceForMeasure(:) = 0;
    stationTable.minFieldValue(:)         = 0;
    stationTable.meanFieldValue(:)        = 0;
    stationTable.maxFieldValue(:)         = 0;

    stationTable.maxFieldTimestamp(:)     = NaT;
    stationTable.maxFieldTimestamp.Format = 'dd/MM/yyyy HH:mm:ss';
    stationTable.maxFieldLatitude(:)      = 0;
    stationTable.maxFieldLongitude(:)     = 0;

    stationTable.("Fonte de dados")(:)    = {''};
    stationTable.("Justificativa")(:)     = categorical("-1", appGeneral.MonitoringPlan.NoMeasureReasons);
    stationTable.("Observações")(:)       = {''};

    stationTable.AnalysisFlag(:)          = false;
    stationTable.UploadResultFlag(:)      = false;
    

    % Ordenando lista (evitando que "Águas Claras" seja apresentada 
    % depois dos municípios que se iniciam com a letra "z")
    referenceList = unique(stationTable.Location);
    referenceEditedList = textAnalysis.normalizeWords(lower(referenceList));
    [~, idxSort] = sort(referenceEditedList);
    
    refListOfLocations = referenceList(idxSort);
    refListOfStates    = unique(stationTable.UF);
end