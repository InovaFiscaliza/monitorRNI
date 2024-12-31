function stationTable = MonitoringPlan(fileFullPath, appGeneral)
    stationTable = readtable(fileFullPath, 'VariableNamingRule', 'preserve');

    % Dados inválidos (Coordenada geográficas):
    idxInvalid = isnan(stationTable.Lat) | isnan(stationTable.Long);
    if any(idxInvalid)
        stationTable(idxInvalid, :)       = [];
    end

    % Filtro por ano:
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
    stationTable.minFieldValue(:)         = 0;
    stationTable.meanFieldValue(:)        = 0;
    stationTable.maxFieldValue(:)         = 0;

    stationTable.maxFieldTimestamp(:)     = NaT;
    stationTable.maxFieldTimestamp.Format = 'dd/MM/yyyy HH:mm:ss';
    stationTable.maxFieldLatitude(:)      = 0;
    stationTable.maxFieldLongitude(:)     = 0;

    stationTable.("Justificativa")        = repmat(categorical("-1", appGeneral.MonitoringPlan.NoMeasureReasons), height(stationTable), 1);
    stationTable.("Observações")          = repmat({''}, height(stationTable), 1);

    stationTable.AnalysisFlag             = false(height(stationTable), 1);
    stationTable.UploadResultFlag         = false(height(stationTable), 1);
end