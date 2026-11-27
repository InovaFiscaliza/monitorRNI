classdef (Abstract) ManualMeasurementFile

    % ## model.ManualMeasurementFile ##
    % Gravação e leitura da planilha "Tabela de Resultados de Medição da 
    % Exposição Humana a CEMRF" (aba "Tabela de Medições"), utilizada para
    % registrar as medidas inseridas manualmente em auxApp.dockManualMeasurement.
    %
    % A planilha modelo acompanha o app (pasta "resources") e possui 14 linhas 
    % de medidas (B9:Q22). Caso haja mais medidas, linhas são inseridas antes 
    % do rodapé - operação que demanda o Excel instalado (Windows).
    %
    % • Colunas da tabela de medidas:
    %   B: Ponto de Medição (P1, P2...)              D: Data e hora (dd/mm/aaaa hh:mm)
    %   F: N° da Estação                             G/H: Latitude/Longitude da Estação
    %   I: Município                                 J: UF
    %   K: Tipo de Medição                           L: Faixa de Frequência
    %   M/N: Latitude/Longitude do Ponto de Medição  O: Valor médio (RMS)
    %   P: Valor de pico                             Q: Componente medida
    %
    % • A planilha não possui campos para altitude e para número de série, 
    %   razão pela qual essas informações não são gravadas. A faixa de frequência 
    %   (coluna L) é inferida do modelo do medidor (model.EMFieldData.getManualSensorBand).

    properties (Constant)
        %-----------------------------------------------------------------%
        TEMPLATE_FILE    = 'Tabela de Resultados de Medição da Exposição Humana a CEMRF.xlsx'
        SHEET_NAME       = 'Tabela de Medições'
        FIRST_DATA_ROW   = 9
        TEMPLATE_ROWS    = 14
        MEASUREMENT_TYPE = 'Portátil'
        FIELD_COMPONENT  = 'E (V/m)'
    end


    methods (Static = true)
        %-----------------------------------------------------------------%
        function templateFullPath = templateFile(rootFolder)
            % Uma cópia em "ProgramData\...\DataBase" tem precedência sobre a que 
            % acompanha o app ("resources").
            fileName = model.ManualMeasurementFile.TEMPLATE_FILE;
            [~, programDataFolder] = appEngine.util.Path(class.Constants.appName, rootFolder);

            candidates = {fullfile(programDataFolder, 'DataBase', fileName), ...
                          fullfile(rootFolder, 'resources', fileName)};
            fileIdx = find(cellfun(@isfile, candidates), 1);
            if isempty(fileIdx)
                error('model:ManualMeasurementFile:TemplateNotFound', 'Planilha modelo "%s" não encontrada.', fileName)
            end

            templateFullPath = candidates{fileIdx};
        end

        %-----------------------------------------------------------------%
        function write(manualTable, stationInfo, outputFile, templateFullPath)
            % "manualTable" possui o formato de model.ProjectBase.initializeCustomTable('MANUALMEASUREMENT'), 
            % devendo conter as medidas de uma única estação e sensor. Os demais 
            % dados da estação (struct com os campos "Latitude", "Longitude", 
            % "Municipality" e "UF") são fornecidos por "stationInfo".
            sheetName = model.ManualMeasurementFile.SHEET_NAME;
            firstRow  = model.ManualMeasurementFile.FIRST_DATA_ROW;
            numRows   = height(manualTable);

            if numRows == 0
                error('model:ManualMeasurementFile:EmptyTable', 'Não há medidas a serem exportadas.')
            end

            [status, msg] = copyfile(templateFullPath, outputFile, 'f');
            if ~status
                error('model:ManualMeasurementFile:CopyFailed', '%s', msg)
            end
            fileattrib(outputFile, '+w');

            if numRows > model.ManualMeasurementFile.TEMPLATE_ROWS
                model.ManualMeasurementFile.insertRows(outputFile, sheetName, firstRow+model.ManualMeasurementFile.TEMPLATE_ROWS-1, numRows-model.ManualMeasurementFile.TEMPLATE_ROWS)
            end

            % Cabeçalho (o valor é registrado na própria célula do rótulo).
            info = manualTable(1, :);
            writecell({sprintf('Entidade Fiscalizada: %s',                info.Entity{1})},  outputFile, 'Sheet', sheetName, 'Range', 'B4')
            writecell({sprintf('Serviço: %s',                             info.Service{1})}, outputFile, 'Sheet', sheetName, 'Range', 'B5')
            writecell({sprintf('Unidade Descentralizada: %s',             info.UD{1})},      outputFile, 'Sheet', sheetName, 'Range', 'F5')
            writecell({sprintf('Medidor utilizado (Marca/Modelo): %s',    info.Sensor{1})},  outputFile, 'Sheet', sheetName, 'Range', 'B6')
            writecell({sprintf('Patrimônio: %s',                          info.SIADS{1})},   outputFile, 'Sheet', sheetName, 'Range', 'H6')

            % Medidas. As colunas C e E são evitadas por pertencerem a células 
            % mescladas (B:C e D:E).
            points     = cellstr(compose('P%d', (1:numRows)'));
            timestamps = cellstr(string(manualTable.Timestamp, 'dd/MM/yyyy HH:mm'));
            bandText   = model.EMFieldData.getManualSensorBand(info.Sensor{1});
            if strcmp(bandText, '(Não informada)')
                bandText = '';
            end
            block       = [ ...
                num2cell(manualTable.Station),          ...
                num2cell(repmat(stationInfo.Latitude,  numRows, 1)), ...
                num2cell(repmat(stationInfo.Longitude, numRows, 1)), ...
                repmat({char(stationInfo.Municipality)}, numRows, 1), ...
                repmat({char(stationInfo.UF)},           numRows, 1), ...
                repmat({model.ManualMeasurementFile.MEASUREMENT_TYPE}, numRows, 1), ...
                repmat({bandText}, numRows, 1),         ...
                num2cell(manualTable.Latitude),         ...
                num2cell(manualTable.Longitude),        ...
                num2cell(manualTable.FieldValue),       ...
                cell(numRows, 1),                       ...
                repmat({model.ManualMeasurementFile.FIELD_COMPONENT}, numRows, 1) ...
            ];

            writecell(points,     outputFile, 'Sheet', sheetName, 'Range', sprintf('B%d', firstRow))
            writecell(timestamps, outputFile, 'Sheet', sheetName, 'Range', sprintf('D%d', firstRow))
            writecell(block,      outputFile, 'Sheet', sheetName, 'Range', sprintf('F%d', firstRow))
        end

        %-----------------------------------------------------------------%
        function data = read(fileName)
            sheetName = model.ManualMeasurementFile.SHEET_NAME;
            firstRow  = model.ManualMeasurementFile.FIRST_DATA_ROW;

            if ~ismember(sheetName, sheetnames(fileName))
                error('model:ManualMeasurementFile:InvalidFormat', 'A planilha não possui a aba "%s".', sheetName)
            end

            % O intervalo é explícito para que as coordenadas das células 
            % coincidam com os índices da matriz (A1 = raw{1,1}).
            raw = readcell(fileName, 'Sheet', sheetName, 'Range', 'A1:Q500');

            data = struct( ...
                'Entity',  afterColon(cellText(raw, 4, 2)), ...
                'Service', afterColon(cellText(raw, 5, 2)), ...
                'UD',      afterColon(cellText(raw, 5, 6)), ...
                'Sensor',  afterColon(cellText(raw, 6, 2)), ...
                'SIADS',   afterColon(cellText(raw, 6, 8)) ...
            );

            timestamps = NaT(0, 1);
            latitudes  = zeros(0, 1);
            longitudes = zeros(0, 1);
            fieldValue = zeros(0, 1);
            invalidRows = [];

            for rowIdx = firstRow:size(raw, 1)
                if startsWith(cellText(raw, rowIdx, 2), 'Observa')
                    break
                end

                latitude  = cellNumber(raw, rowIdx, 13);
                longitude = cellNumber(raw, rowIdx, 14);
                value     = cellNumber(raw, rowIdx, 15);
                if any(isnan([latitude, longitude, value]))
                    continue
                end

                timestamp = cellDatetime(raw, rowIdx, 4);
                if isnat(timestamp)
                    invalidRows(end+1) = rowIdx; %#ok<AGROW>
                    continue
                end

                if isempty(timestamps)
                    data.Station          = cellNumber(raw, rowIdx, 6);
                    data.StationLatitude  = cellNumber(raw, rowIdx, 7);
                    data.StationLongitude = cellNumber(raw, rowIdx, 8);
                    data.Municipality     = cellText(raw, rowIdx, 9);
                    data.UF               = cellText(raw, rowIdx, 10);
                end

                timestamps(end+1, 1) = timestamp; %#ok<AGROW>
                latitudes(end+1, 1)  = latitude;  %#ok<AGROW>
                longitudes(end+1, 1) = longitude; %#ok<AGROW>
                fieldValue(end+1, 1) = value;     %#ok<AGROW>
            end

            if ~isempty(invalidRows)
                error('model:ManualMeasurementFile:InvalidTimestamp', 'Data e hora inválida (esperado dd/mm/aaaa hh:mm) na(s) linha(s): %s.', strjoin(string(invalidRows), ', '))
            end

            if isempty(timestamps)
                error('model:ManualMeasurementFile:NoMeasurements', 'Não foram identificadas medidas na planilha.')
            end

            timestamps.Format = 'dd/MM/yyyy HH:mm:ss';
            data.Measurements = table(timestamps, latitudes, longitudes, zeros(size(fieldValue)), fieldValue, ...
                'VariableNames', {'Timestamp', 'Latitude', 'Longitude', 'Altitude', 'FieldValue'});
        end
    end


    methods (Static = true, Access = private)
        %-----------------------------------------------------------------%
        function insertRows(outputFile, sheetName, templateRow, numRows)
            % As linhas inseridas replicam o formato (inclusive células mescladas)
            % da última linha de medidas do modelo.
            if ~ispc
                error('model:ManualMeasurementFile:ExcelRequired', 'A exportação de mais de %d medidas por planilha demanda o Excel (Windows).', model.ManualMeasurementFile.TEMPLATE_ROWS)
            end

            hExcel = actxserver('Excel.Application');
            cleanupObj = onCleanup(@() quitExcel(hExcel));
            hExcel.DisplayAlerts = false;

            hWorkbook = invoke(hExcel.Workbooks, 'Open', outputFile);
            hSheet    = hWorkbook.Sheets.Item(sheetName);

            invoke(hSheet.Rows.Item(templateRow), 'Copy');
            invoke(hSheet.Range(sprintf('%d:%d', templateRow+1, templateRow+numRows)), 'Insert');
            hExcel.CutCopyMode = 0;

            invoke(hWorkbook, 'Save');
            invoke(hWorkbook, 'Close', false);
        end
    end
end


%-------------------------------------------------------------------------%
function quitExcel(hExcel)
    try
        invoke(hExcel, 'Quit');
        delete(hExcel)
    catch
    end
end


%-------------------------------------------------------------------------%
function text = afterColon(text)
    text = strtrim(regexprep(text, '^[^:]*:\s*', ''));
end

%-------------------------------------------------------------------------%
function text = cellText(raw, rowIdx, colIdx)
    text = '';
    if rowIdx > size(raw, 1) || colIdx > size(raw, 2)
        return
    end

    value = raw{rowIdx, colIdx};
    if ischar(value) || isstring(value)
        text = strtrim(char(value));
    elseif isnumeric(value) && isscalar(value) && ~isnan(value)
        text = num2str(value);
    elseif isdatetime(value) && ~isnat(value)
        text = char(value);
    end
end

%-------------------------------------------------------------------------%
function value = cellNumber(raw, rowIdx, colIdx)
    value = NaN;
    if rowIdx > size(raw, 1) || colIdx > size(raw, 2)
        return
    end

    content = raw{rowIdx, colIdx};
    if isnumeric(content) && isscalar(content)
        value = double(content);
    elseif ischar(content) || isstring(content)
        value = str2double(replace(strtrim(char(content)), ',', '.'));
    end
end

%-------------------------------------------------------------------------%
function timestamp = cellDatetime(raw, rowIdx, colIdx)
    timestamp = NaT;
    if rowIdx > size(raw, 1) || colIdx > size(raw, 2)
        return
    end

    content = raw{rowIdx, colIdx};
    if isdatetime(content)
        timestamp = content;
    elseif isnumeric(content) && isscalar(content) && ~isnan(content)
        timestamp = datetime(content, 'ConvertFrom', 'excel');
    elseif ischar(content) || isstring(content)
        for inputFormat = {'dd/MM/yyyy HH:mm:ss', 'dd/MM/yyyy HH:mm', 'dd/MM/yyyy'}
            try
                timestamp = datetime(strtrim(char(content)), 'InputFormat', inputFormat{1});
                break
            catch
            end
        end
    end
end
