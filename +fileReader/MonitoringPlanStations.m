function stationTable = MonitoringPlanStations(fileFullPath, appGeneral)
    stationTable = readtable(fileFullPath, 'VariableNamingRule', 'preserve');
    
    % Tipos de dados:
    stationTable.("N° Fistel")            = uint64(stationTable.("N° Fistel"));
    stationTable.("N° da Estacao")        = uint32(stationTable.("N° da Estacao"));
    stationTable.('Latitude da Estação')  = str2double(replace(stationTable.('Latitude da Estação'),  ',', '.'));
    stationTable.('Longitude da Estação') = str2double(replace(stationTable.('Longitude da Estação'), ',', '.'));
    
    % Novas colunas:
    stationTable.Location                 = strcat(stationTable.("Municipio"), '/', stationTable.UF);
    stationTable.AnalysisFlag             = false(height(stationTable), 1);
    stationTable.numberOfMeasures(:)      = 0;
    stationTable.numberOfRiskMeasures(:)  = 0;
    stationTable.minFieldValue(:)         = 0;
    stationTable.meanFieldValue(:)        = 0;
    stationTable.maxFieldValue(:)         = 0;
    stationTable.maxFieldTimestamp(:)     = NaT;
    stationTable.maxFieldLatitude(:)      = 0;
    stationTable.maxFieldLongitude(:)     = 0;
    stationTable.("Justificativa")        = repmat(categorical("-1", appGeneral.MonitoringPlan.NoMeasureReasons), height(stationTable), 1);
    stationTable.("Observações")          = repmat({''}, height(stationTable), 1);
end