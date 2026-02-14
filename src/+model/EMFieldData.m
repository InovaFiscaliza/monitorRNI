classdef EMFieldData < handle

    % SINTAXE:
    % >> EMFieldObj = model.EMFieldData.empty;
    % >> EMFieldObj = addFiles(EMFieldObj, {'Filename1.txt', 'Filename2.txt'});

    properties
        %-----------------------------------------------------------------%
        FileName
        FileFullName
        
        Content

        Sensor
        MetaData
        
        Data
        Measures
        FieldValueLimits % V/m

        ObservationTime
        CoveredDistanceKm
        LatitudeLimits
        LongitudeLimits
        Latitude
        Longitude

        % "Location_I" corresponde à localidade de agrupamento, que é identificada 
        % automaticamente pelo app ao parsear o arquivo. "Location", por outro lado, 
        % registra eventuais edições manuais na GUI desse valor.
        Location
        Location_I

        % "UUID" identifica unicamente o objeto, enquanto "Hash" identifica
        % unicamente o conteúdo do objeto, em especial das propriedades "Sensor",
        % "Measures", "ObservationTime", "FieldValueLimits", "LatitudeLimits" 
        % e "LongitudeLimits".
        UUID
        Hash
    end


    methods
        %-----------------------------------------------------------------%
        function obj = EMFieldData(fileFullName, sensorName, metaData, dataTable, contentSample)
            arguments
                fileFullName  char
                sensorName    char {mustBeMember(sensorName, {'Wavecontrol', 'Narda'})}
                metaData      struct
                dataTable     timetable
                contentSample char = ''
            end

            [~, fileName, fileExt] = fileparts(fileFullName);
            obj.FileFullName = fileFullName;
            obj.FileName = [fileName, fileExt];
            obj.Content = contentSample;
            
            obj.Sensor = sensorName;
            obj.MetaData = metaData;
            
            % Ordena dados temporalmente, caso necessário.
            if ~issorted(dataTable.Timestamp)
                dataTable = sortrows(dataTable, 'Timestamp');
            end
            dataTable.Timestamp.Format = 'dd/MM/yyyy HH:mm:ss';
            
            obj.Data = dataTable;
            obj.Measures = height(dataTable);

            % Identifica período de observação e limites de campo elétrico.
            obj.ObservationTime  = sprintf('%s - %s', dataTable.Timestamp(1), dataTable.Timestamp(end));
            [minField, maxField] = bounds(obj.Data.FieldValue);
            obj.FieldValueLimits = [minField, maxField];

            % Identifica limites da rota e localidade que engloba o ponto 
            % central da rota. Além disso, estima-se a distância percorrida
            % na rota.
            [minLat,  maxLat] = bounds(dataTable.Latitude);
            [minLong, maxLong] = bounds(dataTable.Longitude);
            
            obj.LatitudeLimits = round([minLat;  maxLat],  6);
            obj.LongitudeLimits = round([minLong; maxLong], 6);
            
            obj.Latitude = round(mean(dataTable.Latitude),  6);
            obj.Longitude = round(mean(dataTable.Longitude), 6);            
            obj.Location = gpsLib.findNearestCity(struct('Latitude', obj.Latitude, 'Longitude', obj.Longitude));
            obj.Location_I = obj.Location;
            obj.CoveredDistanceKm = round(sum(deg2km(distance(dataTable.Latitude(2:end), dataTable.Longitude(2:end), dataTable.Latitude(1:end-1), dataTable.Longitude(1:end-1)))), 6);

            obj.UUID = char(matlab.lang.internal.uuid());
            obj.Hash = model.ProjectBase.computeEMFieldDataHash(obj);
        end

        %-----------------------------------------------------------------%
        function [obj, msg] = addFiles(obj, fileNameList)
            if ~iscellstr(fileNameList)
                fileNameList = cellstr(fileNameList);
            end

            DIRECTION_MAPPING = dictionary( ...
                {'S', 'W', 'N', 'E'}, ...
                [-1, -1, 1, 1] ...
            );

            msg = {};

            for ii = 1:numel(fileNameList)
                fileFullName = fileNameList{ii};
                if any(ismember(fileFullName, {obj.FileFullName}))
                    continue
                end

                idx = numel(obj)+1;

                try
                    fileContent = fileread(fileFullName);
    
                    [sensorName, ...
                     regExp1,    ...
                     regExp2,    ...
                     dateFormat] = model.EMFieldData.getSensorName(fileFullName, fileContent);
                    metaData = model.EMFieldData.getMetaData(fileContent, sensorName, regExp1);
        
                    rawData = regexp(fileContent, regExp2, 'names');
                    if isempty(rawData)
                        error('model:EMFieldData:NoValidMeasurements','No valid measurements')
                    end
                    
                    latValues = str2double({rawData.LatValue}');
                    lngValues = str2double({rawData.LongValue}');
        
                    dataTable = timetable( ...
                        datetime({rawData.Timestamp}', 'InputFormat', dateFormat, 'Format', 'dd/MM/yyyy HH:mm:ss'), ...
                        DIRECTION_MAPPING({rawData.LatOrientation}')  .* round(floor(latValues/100) + 100*(latValues/100 - floor(latValues/100))/60, 6), ...
                        DIRECTION_MAPPING({rawData.LongOrientation}') .* round(floor(lngValues/100) + 100*(lngValues/100 - floor(lngValues/100))/60, 6), ...
                        round(str2double({rawData.FieldValue}), 6)', ...
                        'VariableNames', {'Latitude', 'Longitude', 'FieldValue'}, ...
                        'DimensionNames', {'Timestamp', 'Variables'} ...
                    );
        
                    contentSample = strtrim(splitlines(fileContent));
                    contentSample(cellfun(@(x) isempty(x), contentSample)) = [];
                    contentSample = strjoin(contentSample, '\n');
                    contentSample = contentSample(1:min(1000, numel(contentSample)));
        
                    obj(idx) = model.EMFieldData(fileFullName, sensorName, metaData, dataTable, contentSample);
                    if any(ismember(obj(idx).Hash, {obj(1:idx-1).Hash}))
                        [~, fileName, fileExt] = fileparts(fileFullName);
                        error('model:EMFieldData:DuplicateFileContent', 'Duplicate file content detected. The file "%s" has the same content hash as a previously parsed file.', [fileName fileExt])
                    end

                catch ME
                    delete(obj(idx))
                    obj(idx) = [];
                    msg{end+1} = ME.message;
                end
            end
        end

        %-----------------------------------------------------------------%
        function measTable = buildMeasurementTable(obj)
            % Concatena as tabelas de LATITUDE, LONGITUDE E NÍVEL de cada um
            % dos arquivos cuja localidade coincide com o que foi selecionado
            % em tela. Além disso, insere o nome do próprio arquivo p/ fins de 
            % mapeamento entre os dados e os arquivos brutos.

            measTable = [];
            tableList = {obj.Data};

            if ~isempty(tableList)
                fileList = cellfun(@(x,y) repmat({x}, y, 1), {obj.FileName}, {obj.Measures}, 'UniformOutput', false);
                tempMeasTable = vertcat(tableList{:});
                tempMeasTable.FileSource = vertcat(fileList{:});        
                measTable = sortrows(tempMeasTable, 'Timestamp');                
            end
        end
    end


    methods (Static = true)
        %-----------------------------------------------------------------%
        function [sensorName, regExpression1, regExpression2, dateFormat] = getSensorName(fileFullName, fileContent)
            % Inicialmente, busca-se no conteúdo do arquivo um TAG que 
            % identifica o sensor. (TAG explícito em contains)
            sensorName = '';
            if     contains(fileContent, 'Wavecontrol MonitEM data',         'IgnoreCase', true)
                sensorName = 'Wavecontrol';        
            elseif contains(fileContent, {'Narda', 'Nsts,AMB-8059', 'MES='}, 'IgnoreCase', true)
                sensorName = 'Narda';
            end
    
            % Caso o cabeçalho do arquivo de medição tenha sido excluído ou
            % editado, pode não ser possível identificar o sensor. Busca-se
            % essa informação, portanto, um TAG no nome do arquivo. 
            % (TAG explícito em contains)
            if isempty(sensorName)
                [~, fileName] = fileparts(fileFullName);
                if     contains(fileName, 'monitEM', 'IgnoreCase', true)
                    sensorName = 'Wavecontrol';
                elseif contains(fileName, '8059Log', 'IgnoreCase', true)
                    sensorName = 'Narda';
                end
            end
    
            switch sensorName
                case 'Wavecontrol'
                    regExpression1  = 'MonitEM Serial:\s*(?<MonitEMSerial>\w*)\s*Probe serial:\s*(?<ProbeSerial>\w+)\s*Frecuencies:\s*(?<Band>[\w\-]+)';
                    regExpression2  = '(?<Timestamp>\d{4}/\d{2}/\d{2},\d{2}:\d{2}:\d{2}),(?<FieldValue>[0-9.]+),\$GPGGA,[0-9.]+,(?<LatValue>[0-9.]+),(?<LatOrientation>[NS]),(?<LongValue>[0-9.]+),(?<LongOrientation>[EW])';
                    dateFormat      = 'yyyy/MM/dd,HH:mm:ss';    
                case 'Narda'
                    regExpression1  = 'IDN=(?<IDN>\w+);Nsts,(?<Model>[^;]+);[^;]+;(?<Serial>\w+);';
                    regExpression2  = 'MES=(?<FieldValue>[0-9.]+);[^$]*\$G(N|P)RMC,[0-9.]+,A,(?<LatValue>[0-9.]+),(?<LatOrientation>[NS]),(?<LongValue>[0-9.]+),(?<LongOrientation>[EW])[^>]*-->(?<Timestamp>\d{2}/\d{2}/\d{2}\s+\d{2}:\d{2}:\d{2})';
                    dateFormat      = 'dd/MM/yy HH:mm:ss';    
                otherwise
                    error('model:EMFieldData:UnexpectedSensorName', 'Unexpected sensor "%s"', sensorName)
            end
        end
    
        %-----------------------------------------------------------------%
        function metaData = getMetaData(fileContent, sensorName, regExpression)
            rawMetaData = regexp(fileContent, regExpression, 'names', 'once');
    
            if ~isempty(rawMetaData)
                switch sensorName
                    case 'Wavecontrol'
                        probeSerial = rawMetaData.ProbeSerial;
                        if ~isempty(rawMetaData.MonitEMSerial)
                            probeSerial = [rawMetaData.MonitEMSerial '-' probeSerial];
                        end        
                        metaData = struct('Model', 'MonitEM', 'Serial', probeSerial, 'Band', rawMetaData.Band, 'Unit', 'V/m');        
                    case 'Narda'
                        probeSerial = rawMetaData.Serial;
                        if isempty(rawMetaData.Serial) && ~isempty(rawMetaData.IDN)
                            probeSerial = rawMetaData.IDN;
                        end    
                        metaData = struct('Model', rawMetaData.Model, 'Serial', probeSerial, 'Band', '100kHz–3GHz', 'Unit', 'V/m');
                end    
            else
                switch sensorName
                    case 'Wavecontrol'
                        metaData = struct('Model', 'MonitEM',     'Serial', '(Não identificado)', 'Band', '100kHz-8GHz', 'Unit', 'V/m');
                    case 'Narda'
                        metaData = struct('Model', 'AMB-8059-00', 'Serial', '(Não identificado)', 'Band', '100kHz–3GHz', 'Unit', 'V/m');
                end
            end
        end
    end

end