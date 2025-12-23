function [stationTable, referenceData] = MonitoringPlan(appName, rootFolder, generalSettings)
    
    [projectFolder, ...
     programDataFolder] = appEngine.util.Path(appName, rootFolder);

    projectFilePath     = fullfile(projectFolder,     'DataBase', [generalSettings.MonitoringPlan.ReferenceFile '.mat']);
    programDataFilePath = fullfile(programDataFolder, 'DataBase', [generalSettings.MonitoringPlan.ReferenceFile '.mat']);

    if isfile(programDataFilePath)
        load(programDataFilePath, 'stationTable');
    else
        load(projectFilePath,     'stationTable')
    end

    % Dados inválidos (Coordenada geográficas):
    idxInvalid = isnan(stationTable.Lat) | isnan(stationTable.Long);
    if any(idxInvalid)
        stationTable(idxInvalid, :)       = [];
    end

    % Filtro por ano:
    listOfYears = unique(stationTable.Ano);
    idxFilter   = ~ismember(stationTable.Ano, generalSettings.MonitoringPlan.Period);
    if any(idxFilter)
        stationTable(idxFilter, :)        = [];
    end
    
    % Conversões:
    stationTable.Fistel                   = uint64(stationTable.Fistel);
    stationTable.("Estação")              = uint32(stationTable.("Estação"));

    % Dados inválidos (Duplicados por possuírem mesmos valores p/ colunas 
    % "Fistel", "Nº estação", "Lat" e "Long"):
    stationTable   =  model.projectLib.generateHash(stationTable, 'stationTable');
    [~, idxUnique] = unique(stationTable.Base64Hash, 'stable');
    stationTable   = stationTable(idxUnique, :);
    
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
    stationTable.("Justificativa")(:)     = categorical("-1", generalSettings.MonitoringPlan.NoMeasureReasons);
    stationTable.("Observações")(:)       = {''};

    stationTable.AnalysisFlag(:)          = false;
    

    % Ordenando lista (evitando que "Águas Claras" seja apresentada 
    % depois dos municípios que se iniciam com a letra "z")
    referenceList   = unique(stationTable.Location);
    referenceEditedList = textAnalysis.normalizeWords(lower(referenceList));
    [~, idxSort] = sort(referenceEditedList);
    
    listOfLocations = referenceList(idxSort);
    listOfStates    = unique(stationTable.UF);

    referenceData   = struct('years',      listOfYears,      ...
                             'locations', {listOfLocations}, ...
                             'states',    {listOfStates});
end