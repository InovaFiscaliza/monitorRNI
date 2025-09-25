function [status, msgError] = MonitoringPlan(projectData, fileName, stationTable, measTable, ReferenceFielValue, RawMeasuresExportFlag)

    arguments
        projectData
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
        %     caso editadas, e troca valores inválidos ("-1", por exemplo) por 
        %     valores nulos.
        stationTable = prepareStationTableForExport(projectData, stationTable);
    
        % (b) Seleciona colunas que irão compor o arquivo .XLSX, criando coluna 
        %     com informação do "Limite".
        stationTable = stationTable(:, [1:13, 19:30]);
        stationTable.("Limite (V/m)")(:) = ReferenceFielValue;
    
        % (c) Edita nomes de algumas das colunas da tabela.
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