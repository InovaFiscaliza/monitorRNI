function [status, msgError] = ExternalRequest(fileName, pointsTable, measTable, ReferenceFielValue, RawMeasuresExportFlag)

    arguments
        fileName 
        pointsTable 
        measTable 
        ReferenceFielValue 
        RawMeasuresExportFlag = false
    end

    status = true;
    msgError = '';

    try
        % PREPARA TABELA    
        % (a) Seleciona colunas que irão compor o arquivo .XLSX, criando coluna 
        %     com informação do "Limite".
        pointsTable = pointsTable(:, 1:end-1);
        pointsTable.("Limite (V/m)")(:) = ReferenceFielValue;
    
        % (b) Troca valores inválidos ("-1", por exemplo) por valores nulos.
        pointsTable.("Justificativa") = replace(cellstr(pointsTable.("Justificativa")), '-1', '');
    
        % (c) Edita nomes de algumas das colunas da tabela.
        pointsTable.Properties.VariableNames([2:3, 6:end-2]) = {'Tipo',                         ...
                                                                'Estação',                      ...
                                                                'Descrição',                    ...
                                                                'Qtd. Medidas',                 ...
                                                                'Qtd. Medidas Acima do Limite', ...
                                                                'Distância Mínima (km)',        ...
                                                                'Emin (V/m)',                   ...
                                                                'Emean (V/m)',                  ...
                                                                'Emax (V/m)',                   ...
                          	                                    'Emax - Latitude',              ...
                        	                                    'Emax - Longitude'};
        pointsTable = movevars(pointsTable, 'Limite (V/m)', 'After', 'Qtd. Medidas Acima do Limite');
    
        % SALVA ARQUIVO
        writetable(pointsTable, fileName, 'FileType', 'spreadsheet', 'WriteMode', 'replacefile', 'Sheet', 'POINTS')
    
        if RawMeasuresExportFlag
            writetable(measTable, fileName, 'FileType', 'spreadsheet', 'WriteMode', 'overwritesheet', 'Sheet', 'MEASURES')
        end

    catch ME
        status = false;
        msgError = ME.message;
    end
end