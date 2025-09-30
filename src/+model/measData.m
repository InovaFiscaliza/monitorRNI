classdef measData < handle

    properties
        %-----------------------------------------------------------------%
        Filepath
        Filename

        Content

        Sensor
        MetaData
        
        Data
        Measures
        FieldValueLimits % V/m

        ObservationTime
        CoveredDistance  % km
        LatitudeLimits
        LongitudeLimits
        Latitude
        Longitude

        Location
        Location_I

        UUID
    end


    methods
        %-----------------------------------------------------------------%
        function obj = measData(fileFullName, Sensor, metaData, dataTable, contentSample)
            arguments
                fileFullName  char
                Sensor        char {mustBeMember(Sensor, {'Wavecontrol', 'Narda'})}
                metaData      struct
                dataTable     timetable
                contentSample char = ''
            end

            [filePath, fileName, fileExt] = fileparts(fileFullName);
            obj.Filepath  = filePath;
            obj.Filename  = [fileName, fileExt];
            obj.Content   = contentSample;
            
            obj.Sensor    = Sensor;
            obj.MetaData  = metaData;
            
            % Ordena dados temporalmente, caso necessário.
            if ~issorted(dataTable.Timestamp)
                dataTable = sortrows(dataTable, 'Timestamp');
            end
            dataTable.Timestamp.Format = 'dd/MM/yyyy HH:mm:ss';
            
            obj.Data      = dataTable;
            obj.Measures  = height(dataTable);

            % Identifica período de observação e limites de campo elétrico.
            obj.ObservationTime  = sprintf('%s - %s', dataTable.Timestamp(1), dataTable.Timestamp(end));
            [minField, maxField] = bounds(obj.Data.FieldValue);
            obj.FieldValueLimits = [minField, maxField];

            % Identifica limites da rota e localidade que engloba o ponto 
            % central da rota. Além disso, estima-se a distância percorrida
            % na rota.
            [minLat,  maxLat]    = bounds(dataTable.Latitude);
            [minLong, maxLong]   = bounds(dataTable.Longitude);
            
            obj.LatitudeLimits   = round([minLat;  maxLat],  6);
            obj.LongitudeLimits  = round([minLong; maxLong], 6);
            
            obj.Latitude         = round(mean(dataTable.Latitude),  6);
            obj.Longitude        = round(mean(dataTable.Longitude), 6);            
            obj.Location         = gpsLib.findNearestCity(struct('Latitude', obj.Latitude, 'Longitude', obj.Longitude));
            obj.Location_I       = obj.Location;

            obj.CoveredDistance  = round(sum(deg2km(distance(dataTable.Latitude(2:end), dataTable.Longitude(2:end), dataTable.Latitude(1:end-1), dataTable.Longitude(1:end-1)))), 6);
            obj.UUID             = char(matlab.lang.internal.uuid());
        end

        %-----------------------------------------------------------------%
        function measTable = createMeasTable(obj)
            % Concatena as tabelas de LATITUDE, LONGITUDE E NÍVEL de cada um
            % dos arquivos cuja localidade coincide com o que foi selecionado
            % em tela. Além disso, insere o nome do próprio arquivo p/ fins de 
            % mapeamento entre os dados e os arquivos brutos.

            measTable = [];
            listOfTables = {obj.Data};

            if ~isempty(listOfTables)
                listOfFiles   = cellfun(@(x,y) repmat({x}, y, 1), {obj.Filename}, {obj.Measures}, 'UniformOutput', false);
                tempMeasTable = vertcat(listOfTables{:});
                tempMeasTable.FileSource = vertcat(listOfFiles{:});
        
                measTable     = sortrows(tempMeasTable, 'Timestamp');                
            end
        end
    end
end