function [status, msgError] = MonitoringPlan(fileName, stationTable, measTable, ReferenceFielValue, RawMeasuresExportFlag)

    arguments
        fileName 
        stationTable 
        measTable 
        ReferenceFielValue 
        RawMeasuresExportFlag = false
    end

    status = true;
    msgError = '';

    try
        % PREPARA TABELA
        % (a) Insere coordenadas geográficas da estação no campo "Observações", 
        %     caso editadas.
        idxEditedCoordinates = find((stationTable.("Lat") ~= stationTable.("Latitude")) | (stationTable.("Long") ~= stationTable.("Longitude")))';
        for ii = idxEditedCoordinates
            Coordinates = struct('Latitude_Editada',  stationTable.("Latitude")(ii), ...
                                 'Longitude_Editada', stationTable.("Longitude")(ii));
    
            if ~isempty(stationTable.("Observações"){ii})
                Coordinates.NotaAdicional = stationTable.("Observações"){ii};
            end
    
            stationTable.("Observações"){ii} = jsonencode(Coordinates);
        end
    
        % (b) Seleciona colunas que irão compor o arquivo .XLSX.
        stationTable = stationTable(:, [1:13, 19:30]);
    
        % (c) Troca valores inválidos ("-1", por exemplo) por valores nulos.
        stationTable.("Justificativa") = replace(cellstr(stationTable.("Justificativa")), '-1', '');
    
        % (d) Edita nomes de algumas das colunas da tabela.
        stationTable.Properties.VariableNames(14:22) = {'Qtd. medidas',           ...
                                                        sprintf('Qtd. medidas > %.1f V/m', ReferenceFielValue), ...
                                                        'Distância mínima (km)',  ...
                                                        'Emin (V/m)',             ...
                                                        'Emean (V/m)',            ...
                                                        'Emax (V/m)',             ...
                                                        'Emax - Data da Medição', ...
                                  	                    'Emax - Latitude',        ...
                                	                    'Emax - Longitude'};
    
        % SALVA ARQUIVO
        writetable(stationTable, fileName, 'FileType', 'spreadsheet', 'WriteMode', 'replacefile', 'Sheet', 'STATIONS')
    
        if RawMeasuresExportFlag
            writetable(measTable, fileName, 'FileType', 'spreadsheet', 'WriteMode', 'overwritesheet', 'Sheet', 'MEASURES')
        end

    catch ME
        status = false;
        msgError = ME.message;
    end
end