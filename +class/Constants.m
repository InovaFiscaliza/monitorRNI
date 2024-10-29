classdef (Abstract) Constants

    properties (Constant)
        %-----------------------------------------------------------------%
        appName       = 'RNI'
        appRelease    = 'R2024a'
        appVersion    = '0.02'

        windowSize    = [1244, 660]
        windowMinSize = [ 880, 660]
        
        xDecimals     = 5        
        floatDiffTol  = 1e-5

        GUIColumns        = {'UR', 'UF', 'Município', 'Serviço', 'N° Fistel', 'N° da Estação', 'Latitude Estação', 'Longitude Estação'};
       
        GUINewColumns     = {'Data da Medição', 'Valor Medido (V/m)', 'Latitude maior valor Medido', 'Longitude maior valor Medido', 'N° de Medidas acima de 14 V/M', 'Justificativa (apenas para estações sem medições)', 'Observações'}
        
        % Novas colunas para adicionar na UITable
        GUIColumnsAll     = {'UR', 'UF', 'Município', 'Serviço', 'N° Fistel', 'N° da Estação', 'Latitude da Estação', 'Longitude da Estação', 'Data da Medição', 'Emáx (V/m)', 'Latitude Emáx', 'Longitude Emáx', '> 14 V/M', 'Justificativa (apenas NV)', 'Observações importantes'};

        GUIColumnsSelect  = {'UF', 'Município', 'Serviço', 'N° da Estação', 'Data da Medição', 'Emáx (V/m)', 'Latitude Emáx', 'Longitude Emáx', '> 14 V/M', 'Justificativa (apenas NV)', 'Observações importantes'};

        GUIColumns_Sondas = {'DataTime', 'Latitude', 'Longitude', 'E_VM'};

        GuiColumnWidth = {50, 40, 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto'}
        GuiColumnWidthCalc = {50, 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto'}
    end


    methods (Static = true)
        %-----------------------------------------------------------------%
        function fileName = DefaultFileName(userPath, Prefix, Issue)
            arguments
                userPath char
                Prefix   char
                Issue    double = -1
            end

            fileName = fullfile(userPath, sprintf('%s_%s', Prefix, datestr(now,'yyyy.mm.dd_THH.MM.SS')));

            if Issue > 0
                fileName = sprintf('%s_%d', fileName, Issue);
            end
        end
    end
end