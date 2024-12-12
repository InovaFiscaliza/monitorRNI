function msgWarning = KML(stationTable, idxStations, measTable, fileBasename, fileZIP, hPlot)

    % ARQUIVOS DE SAÍDA:
    % - XLSX: para uso no Excel; e
    % - KML: para uso no Google Earth e afins.
    msgWarning = {};
    msgError   = {};

    fileSheetName   = [fileBasename '.xlsx'];
    fileKMLMeasures = [fileBasename '_Measures.kml'];
    fileKMLRoute    = [fileBasename '_Route.kml'];

    % kmlwrite retorna erro quando a entrada é uma timetable. A simples
    % conversão para tabela resolveu.
    measTable = timetable2table(measTable);

    % XLSX
    try
        tempTable = stationTable(idxStations, [1:8, 16, 15, 17:18, 12, 19:20]);
        tempTable.("Justificativa") = replace(cellstr(tempTable.("Justificativa")), '-1', '');
        tempTable.Properties.VariableNames(9:15) = {'Data da Medição',           ...
                                                    'Emáx (V/m)',                ...
                                      	            'Latitude Emáx',             ...
                                    	            'Longitude Emáx',            ...
                                      	            '> 14 V/M',                  ...
                                      	            'Justificativa (apenas NV)', ...
                                      	            'Observações importantes'};

        writetable(tempTable, fileSheetName, 'FileType', 'spreadsheet', 'WriteMode', 'replacefile',    'Sheet', 'STATIONS')
        writetable(measTable, fileSheetName, 'FileType', 'spreadsheet', 'WriteMode', 'overwritesheet', 'Sheet', 'MEASURES')
        msgWarning{end+1} = sprintf('•&thinsp;%s', fileSheetName);
    catch ME
        msgError{end+1}   = ME.message;
    end

    % KML
    measDescription = arrayfun(@(x,y) sprintf('%s\n%.1f V/m', x, y), measTable.Timestamp, measTable.FieldValue, 'UniformOutput', false);
    geoTable = table2geotable(measTable);
    RGB = imageUtil.getRGB(hPlot);

    try
        kmlwrite(fileKMLMeasures, geoTable, 'Name', string(1:height(geoTable))', 'Description', measDescription, 'Color', RGB)
        msgWarning{end+1} = sprintf('•&thinsp;%s', fileKMLMeasures);
    catch ME
        msgError{end+1}   = ME.message;
    end

    try
        routeDescription = sprintf('%s - %s', char(measTable.Timestamp(1)), char(measTable.Timestamp(end)));
        kmlwriteline(fileKMLRoute, measTable.Latitude, measTable.Longitude, 'Name', 'Route', 'Description', routeDescription', 'Color', 'red', 'LineWidth', 3)
        msgWarning{end+1} = sprintf('•&thinsp;%s', fileKMLRoute);
    catch ME
        msgError{end+1}   = ME.message;
    end

    if isempty(msgError)
        zip(fileZIP, {fileSheetName, fileKMLMeasures, fileKMLRoute})
    else
        error('DriveTest:ExportFiles:FileNotCreated', strjoin(msgError, '\n'))
    end

    fileFolder = fileparts(fileBasename);
    msgWarning = replace(msgWarning, fileFolder, '.');
    msgWarning = sprintf('Lista de arquivos criados na pasta de trabalho:\n%s', strjoin(msgWarning, '\n'));
end