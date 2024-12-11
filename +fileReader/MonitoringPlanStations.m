function stationTable = MonitoringPlanStations(fileFullPath)
    stationTable = readtable(fileFullPath, 'VariableNamingRule', 'preserve');
    
    % Subtui as virgulas das coordendas por pontos e tranforma Lat. e Long. para Double
    stationTable.("N° Fistel")            = uint64(stationTable.("N° Fistel"));
    stationTable.("N° da Estacao")        = uint32(stationTable.("N° da Estacao"));
    stationTable.('Latitude da Estação')  = str2double(replace(stationTable.('Latitude da Estação'),  ',', '.'));
    stationTable.('Longitude da Estação') = str2double(replace(stationTable.('Longitude da Estação'), ',', '.'));
    
    % Novas colunas:
    stationTable.Location                 = strcat(stationTable.("Municipio"), '/', stationTable.UF);
    stationTable.numberOfMeasures(:)      = 0;
    stationTable.numberOfRiskMeasures(:)  = 0;
    stationTable.minFieldValue(:)         = 0;
    stationTable.meanFieldValue(:)        = 0;
    stationTable.maxFieldValue(:)         = 0;
    stationTable.maxFieldTimestamp(:)     = NaT;
    stationTable.maxFieldLatitude(:)      = 0;
    stationTable.maxFieldLongitude(:)     = 0;
    stationTable.("Justificativa")        = repmat({''}, height(stationTable), 1);
    stationTable.("Observações")          = stationTable.("Justificativa");
end