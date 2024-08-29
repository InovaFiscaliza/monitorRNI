classdef (Abstract) Constants

    properties (Constant)
        %-----------------------------------------------------------------%
        appName       = 'SCH'
        appRelease    = 'R2024a'
        appVersion    = '0.01'

        windowSize    = [1244, 660]
        windowMinSize = [ 880, 660]
        
        xDecimals     = 5        
        floatDiffTol  = 1e-5

        GUIColumns        = {'ID', 'UR (Unidade Regional)', 'UF', 'Município', 'Serviço', 'N° Fistel', 'N° da Estação', 'Latitude Estação', 'Longitude Estação'};
       
        GUINewColumns     = {'Data da Medição', 'Valor Medido (V/m)', 'Latitude maior valor Medido', 'Longitude maior valor Medido', 'N° de Medidas acima de 14 V/M', 'Justificativa (apenas para estações sem medições)', 'Observações', 'Distância (metros)'}
        
        % Novas colunas para adicionar na UITable
        GUIColumnsAll     = {'ID', 'Unidade regional', 'UF', 'Município', 'Serviço', 'N° Fistel', 'N° da Estação', 'Latitude da Estação', 'Longitude da Estação', 'Data da Medição', 'Valor Medido (V/m)', 'Latitude do maior valor Medido', 'Longitude do maior valor Medido', 'N° de Medidas acima de 14 V/M', 'Justificativa (apenas para estações sem medições)', 'Observações', 'Distância (metros)'};

        GUIColumns_Sondas = {'DataTime', 'Latitude', 'Longitude', 'E_VM'};

        GuiColumnWidth = {40, 50, 50, 170, 170, 100, 100, 100, 100};
        GuiColumnWidthClear = {1, 1, 1, 1, 1, 1, 100, 1, 1, 80, 70, 100, 100, 80, 140, 140, 80};
                                % rawTable

    end
end