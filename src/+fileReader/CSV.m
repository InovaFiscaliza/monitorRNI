classdef (Abstract) CSV

    % Implementados leitores p/ os arquivos gerados pelo Wavecontrol e Narda.
    % A seguir são apresentados recortes dos arquivos.

    % Wavecontrol MonitEM data
    % Date: 03/07/2024 13:47:25
    % MonitEM Serial: 13MT0268
    % Probe serial: 13WP040364
    % Frecuencies: 100kHz-8GHz
    % Units: V/m
    % Date:,Time,Value,GPGGA,gps_time,lat,N/S,lon,E/O,fix,number_satellites,diution,height,M,geoid_height,M,,*CRC,GPGSA,A,3D_fix,PRN,PRN,PRN,PRN,PRN,PRN,PRN,PRN,PRN,PRN,PRN,PRN,PDOP,HDOP,VDOP*CRC
    % 2024/03/07,08:54:22,0.77,$GPGGA,,,,,,0,,,,,,,,*66,$GPGSA,A,1,,,,,,,,,,,,,,,*1E
    % 2024/03/07,08:54:22,0.80,$GPGGA,115156.3,1352.379160,S,04004.614549,W,1,09,1.0,204.8,M,-10.0,M,,*79,$GPGSA,A,3,08,10,18,23,26,27,28,31,32,,,,1.7,1.0,1.4*39
    % 2024/03/07,08:54:23,0.79,$GPGGA,115157.2,1352.379209,S,04004.614754,W,1,09,1.0,204.2,M,-10.0,M,,*71,$GPGSA,A,3,08,10,18,23,26,27,28,31,32,,,,1.7,1.0,1.4*39

    % #BM MDM=OK*
    % #BM MSK=------------*
    % #BM TSS=OFF 16:00 ( 2q)  each 24h*
    % #BM TSM=NET 13:25 ( 1q)  each 04h*
    % #BM MES=0.00; ; V/m*
    % #BM IDN=490ZY30410;Nsts,AMB-8059-00; 2.29 11/22;490ZY30410;07.06.23;NET 13:25 ( 1q)  each 04h;OFF 16:00 ( 2q)  each 24h;------------;*
    % #BM MES=0.00; ; V/m*
    % #BM MDM=OK*
    % MES=0.00; ; ; ; V/m; 3.65V; ;524.00;-8.00;63.00;29.20;57.57 -->04/04/24 08:21:17*;
    % MES=0.00; ; ; ; V/m; 3.65V; ;3.00;4.00;2.00;29.20;57.57 -->04/04/24 08:21:17*;
    % MES=0.18; ; ; ; V/m; 3.58V; $GNRMC,113720.000,A,1102.9237,S,04511.7269,W,0.09,255.45,040424,,,D*68;;-4.00;-27.00;11.00;29.81;57.85 -->04/04/24 08:37:15*;
    % MES=0.20; ; ; ; V/m; 3.58V; $GNRMC,113721.000,A,1102.9237,S,04511.7271,W,0.07,255.45,040424,,,D*6E;;5.00;11.00;-2.00;29.81;57.85 -->04/04/24 08:37:16*;

    methods (Static)
        %-----------------------------------------------------------------%
        function measData  = Controller(fileFullName)
            fileContent    = fileread(fileFullName);

            [sensorName, ...
             regExp1,    ...
             regExp2,    ...
             dateFormat]   = fileReader.CSV.Sensor(fileFullName, fileContent);
            
            % Metadados:
            metaData       = fileReader.CSV.MetaData(fileContent, sensorName, regExp1);
            
            % Tabela:
            rawData        = regexp(fileContent, regExp2, 'names');
            if isempty(rawData)
                error('Não identificada médida válida')
            end
            
            Timestamp      = datetime({rawData.Timestamp}', 'InputFormat', dateFormat, 'Format', 'dd/MM/yyyy HH:mm:ss');
            FieldValue     = str2double({rawData.FieldValue}');
            
            coordinatesDic = dictionary({'S', 'W', 'N', 'E'}, [-1, -1, 1, 1]);
            LatitudeValues = str2double({rawData.LatValue}');
            LongitudeValues= str2double({rawData.LongValue}');
            Latitude       = coordinatesDic({rawData.LatOrientation}')  .* (floor(LatitudeValues/100)  + 100*(LatitudeValues/100  - floor(LatitudeValues/100))/60);
            Longitude      = coordinatesDic({rawData.LongOrientation}') .* (floor(LongitudeValues/100) + 100*(LongitudeValues/100 - floor(LongitudeValues/100))/60);            
            dataTable      = timetable(Timestamp, Latitude, Longitude, FieldValue);

            contentSample  = strtrim(splitlines(fileContent));
            contentSample(cellfun(@(x) isempty(x), contentSample)) = [];
            contentSample  = strjoin(contentSample, '\n');
            contentSample  = contentSample(1:min(1000, numel(contentSample)));

            measData       = model.measData(fileFullName, sensorName, metaData, dataTable, contentSample);
        end

        %-----------------------------------------------------------------%
        function [sensorName, regExpression1, regExpression2, dateFormat] = Sensor(fileFullName, fileContent)
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
                    error('MissingFileID')
            end
        end

        %-----------------------------------------------------------------%
        function metaData = MetaData(fileContent, sensorName, regExpression)
            rawMetaData = regexp(fileContent, regExpression, 'names', 'once');

            if ~isempty(rawMetaData)
                switch sensorName
                    case 'Wavecontrol'
                        Serial = rawMetaData.ProbeSerial;
                        if ~isempty(rawMetaData.MonitEMSerial)
                            Serial = [rawMetaData.MonitEMSerial '-' Serial];
                        end
    
                        metaData = struct('Model',  'MonitEM',         ...
                                          'Serial', Serial,            ...
                                          'Band',   rawMetaData.Band,  ...
                                          'Unit',   'V/m');
    
                    case 'Narda'
                        Serial = rawMetaData.Serial;
                        if isempty(rawMetaData.Serial) && ~isempty(rawMetaData.IDN)
                            Serial = rawMetaData.IDN;
                        end

                        metaData = struct('Model',  rawMetaData.Model, ...
                                          'Serial', Serial,            ...
                                          'Band',   '100kHz–3GHz',     ...
                                          'Unit',   'V/m');
                end

            else
                switch sensorName
                    case 'Wavecontrol'
                        metaData = struct('Model',  'MonitEM',            ...
                                          'Serial', '(Não identificado)', ...
                                          'Band',   '100kHz-8GHz',        ...
                                          'Unit',   'V/m');
    
                    case 'Narda'
                        metaData = struct('Model',  'AMB-8059-00',        ...
                                          'Serial', '(Não identificado)', ...
                                          'Band',   '100kHz–3GHz',        ...
                                          'Unit',   'V/m');
                end
            end
        end
    end
end