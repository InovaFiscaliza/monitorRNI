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

        userPaths     = {fullfile(getenv('USERPROFILE'), 'Documents'); fullfile(getenv('USERPROFILE'), 'Downloads')}

        GUIColumns        = {'ID', 'Unidade regional', 'UF', 'Município', 'Serviço', 'N° Fistel', 'N° da Estação', 'Latitude da Estação', 'Longitude da Estação', 'Data da Medição', 'Valor Medido (V/m)', 'Latitude do maior valor Medido', 'Longitude do maior valor Medido', 'N° de Medidas acima de 14 V/M', 'Justificativa (apenas para estações sem medições)', 'Observações', 'Distância (metros)'};
  
        GUIColumns_Sondas = {'DataTime', 'Latitude', 'Longitude', 'E_VM'};
                                % rawTable
        
        % opts = delimitedTextImportOptions('NumVariables',       17,         ...
        %                                       'Encoding',           'UTF-8',    ...
        %                                       'Delimiter',          ';',        ...
        %                                       'VariableNamingRule', 'preserve', ...
        %                                       'VariableNamesLine',  1,         class( ...
        %                                       'DataLines',          2,          ...
        %                                       'VariableTypes',      {'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'string', 'string', 'string', 'double', 'double', 'string', 'string', 'string'});
    end

    
    methods (Static = true)
        %-----------------------------------------------------------------%
        function fileName = DefaultFileName(userPath, Prefix, Issue)
            fileName = fullfile(userPath, sprintf('%s_%s', Prefix, datestr(now, 'yyyy.mm.dd_THH.MM.SS')));

            if Issue > 0
                fileName = sprintf('%s_%d', fileName, Issue);
            end
        end
    end
end