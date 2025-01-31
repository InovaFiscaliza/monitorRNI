classdef measData < handle

    properties
        %-----------------------------------------------------------------%
        Filepath
        Filename

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

        UserData
    end


    methods
        %-----------------------------------------------------------------%
        function obj = measData(fileFullName, Sensor, metaData, dataTable)
            arguments
                fileFullName char
                Sensor       char {mustBeMember(Sensor, {'Wavecontrol', 'Narda'})}
                metaData     struct
                dataTable    timetable
            end

            [filePath, fileName, fileExt] = fileparts(fileFullName);
            obj.Filepath  = filePath;
            obj.Filename  = [fileName, fileExt];
            
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
            obj.Location         = fcn.gpsFindCity(struct('Latitude', obj.Latitude, 'Longitude', obj.Longitude));   

            obj.CoveredDistance  = round(sum(deg2km(distance(dataTable.Latitude(2:end), dataTable.Longitude(2:end), dataTable.Latitude(1:end-1), dataTable.Longitude(1:end-1)))), 6);
        end
    end
end