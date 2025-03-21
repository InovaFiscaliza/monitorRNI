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
    
        % (b) Seleciona colunas que irão compor o arquivo .XLSX, criando coluna 
        %     com informação do "Limite".
        stationTable = stationTable(:, [1:13, 19:30]);
        stationTable.("Limite (V/m)")(:) = ReferenceFielValue;
    
        % (c) Troca valores inválidos ("-1", por exemplo) por valores nulos.
        stationTable.("Justificativa") = replace(cellstr(stationTable.("Justificativa")), '-1', '');
    
        % (d) Edita nomes de algumas das colunas da tabela.
        stationTable.Properties.VariableNames(14:22) = {'Qtd. Medidas',                 ...
                                                        'Qtd. Medidas Acima do Limite', ...
                                                        'Distância Mínima (km)',        ...
                                                        'Emin (V/m)',                   ...
                                                        'Emean (V/m)',                  ...
                                                        'Emax (V/m)',                   ...
                                                        'Emax - Data da Medição',       ...
                                  	                    'Emax - Latitude',              ...
                                	                    'Emax - Longitude'};
        stationTable = movevars(stationTable, 'Limite (V/m)', 'After', 'Qtd. Medidas Acima do Limite');
    
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