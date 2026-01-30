function [stationTable, referenceData] = MonitoringPlan(appName, rootFolder, generalSettings)
    % Em 29/01/2026, a planilha base do PM-RNI, em formato .xlsx, possui 13 
    % colunas. Antes de exportar essa planilha como .mat, acrescentam-se 
    % outras cinco colunas - "Ano", "Base64Hash", "Location", "Latitude" e 
    % "Longitude".

    % • Colunas 01-07: ["ID", "UD", "UF", "Município", "Tipo", "Serviço", "Entidade"] - cellstr
    % • Coluna     08: ["Fistel"]                                                     - uint64
    % • Coluna     09: ["Estação"]                                                    - uint32
    % • Coluna     10: ["Endereço"]                                                   - cellstr
    % • Colunas 11-12: ["Lat" e "Long"]                                               - double
    % • Coluna     13: ["Áreas Críticas"]                                             - cellstr
    % • Coluna     14: ["Ano"]                                                        - double
    % • Colunas 15-16: ["Base64Hash", "Location"]                                     - cellstr
    % • Colunas 17-18: ["Latitude", "Longitude"]                                      - double

    % No processo de leitura, são eliminados registros que não correspondem 
    % aos anos de interesse. Além disso, são incluídas colunas que auxiliam 
    % no registro da análise realizada por meio do app.
    
    [projectFolder, ...
     programDataFolder] = appEngine.util.Path(appName, rootFolder);

    projectFilePath     = fullfile(projectFolder,     'DataBase', [generalSettings.context.MONITORINGPLAN.referenceFile '.mat']);
    programDataFilePath = fullfile(programDataFolder, 'DataBase', [generalSettings.context.MONITORINGPLAN.referenceFile '.mat']);

    try
        load(programDataFilePath, 'stationTable');
    catch
        load(projectFilePath,     'stationTable')
    end

    idxInvalid = isnan(stationTable.Lat) | isnan(stationTable.Long);
    if any(idxInvalid)
        stationTable(idxInvalid, :) = [];
    end

    yearList = unique(stationTable.Ano);
    idxFilter = ~ismember(stationTable.Ano, generalSettings.context.MONITORINGPLAN.periodYears);
    if any(idxFilter)
        stationTable(idxFilter, :) = [];
    end
    
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
    stationTable.("Justificativa")(:)     = categorical("-", generalSettings.context.MONITORINGPLAN.noMeasurementReasons, 'Protected', true);
    stationTable.("Observações")(:)       = {''};

    stationTable.AnalysisFlag(:)          = false;    

    % Por fim, ordena-se a tabela, de forma que "Águas Claras", por exemplo, 
    % não seja apresentada depois dos municípios que se iniciam com a letra "z".
    locationList = unique(stationTable.Location);
    locationNormalizedList = textAnalysis.normalizeWords(lower(locationList));
    [~, idxSort] = sort(locationNormalizedList);
    
    referenceData = struct( ...
        'years', yearList, ...
        'selectedYears', generalSettings.context.MONITORINGPLAN.periodYears, ...
        'locations', {locationList(idxSort)}, ...
        'states', {unique(stationTable.UF)} ...
    );
end