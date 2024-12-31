function msgWarning = Summary(stationTable, idxStations, measTable, fileBasename, fileZIP, hPlot, appGeneral)

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
        tempTable = stationTable(idxStations, :);

        % "Embutindo" as coordenadas geográficas editadas no campo "Observações". 
        idxEditedCoordinates = find((tempTable.("Lat") ~= tempTable.("Latitude")) | (tempTable.("Long") ~= tempTable.("Longitude")))';
        for ii = idxEditedCoordinates
            Coordinates = struct('Latitude_Editada',  tempTable.("Latitude")(ii), ...
                                 'Longitude_Editada', tempTable.("Longitude")(ii));

            if ~isempty(tempTable.("Observações"){ii})
                Coordinates.NotaAdicional = tempTable.("Observações"){ii};
            end

            tempTable.("Observações"){ii} = jsonencode(Coordinates);
        end

        % Edição de informações p/ que a planilha Excel fique mais "bonitinha"...
        tempTable = tempTable(:, [1:13, 19:28]);
        tempTable.("Justificativa") = replace(cellstr(tempTable.("Justificativa")), '-1', '');
        tempTable.Properties.VariableNames(14:21) = {'Qtd. medidas',          ...
                                                    sprintf('Qtd. medidas > %.1f V/m', appGeneral.MonitoringPlan.FieldValue), ...
                                                    'Emin (V/m)',             ...
                                                    'Emean (V/m)',            ...
                                                    'Emax (V/m)',             ...
                                                    'Emax - Data da Medição', ...
                                      	            'Emax - Latitude',        ...
                                    	            'Emax - Longitude'};

        writetable(tempTable, fileSheetName, 'FileType', 'spreadsheet', 'WriteMode', 'replacefile',    'Sheet', 'STATIONS')
        if appGeneral.MonitoringPlan.Export.XLSX
            writetable(measTable, fileSheetName, 'FileType', 'spreadsheet', 'WriteMode', 'overwritesheet', 'Sheet', 'MEASURES')
        end
        
        msgWarning{end+1} = sprintf('•&thinsp;%s', fileSheetName);
    catch ME
        msgError{end+1}   = ME.message;
    end

    % KML
    if appGeneral.MonitoringPlan.Export.KML
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
    end

    % Arquivo de saída: ZIP
    if isempty(msgError)
        if appGeneral.MonitoringPlan.Export.KML
            zip(fileZIP, {fileSheetName, fileKMLMeasures, fileKMLRoute})
        else
            zip(fileZIP, fileSheetName)
        end
    else
        error('DriveTest:ExportFiles:FileNotCreated', strjoin(msgError, '\n'))
    end

    fileFolder = fileparts(fileBasename);
    msgWarning = replace(msgWarning, fileFolder, '.');
    msgWarning = sprintf('Lista de arquivos criados na pasta de trabalho:\n%s', strjoin(msgWarning, '\n'));
end