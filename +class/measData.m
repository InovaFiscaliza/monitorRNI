classdef measData

    properties
        %-----------------------------------------------------------------%
        Filename

        Sensor
        MetaData
        
        Measures        
        Data

        LatitudeLimits
        LongitudeLimits

        Latitude
        Longitude
        Location

        UserData = struct('MonitoringPlanFlag', false)
    end
end