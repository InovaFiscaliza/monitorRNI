function [status, msgError] = KML(fileName, fileType, measTable, hMeasPlot)

    arguments
        fileName
        fileType {mustBeMember(fileType, {'Measures', 'Route'})}
        measTable
        hMeasPlot = []
    end

    status = true;
    msgError = '';
    
    try    
        switch fileType
            case 'Measures'            
                description  = arrayfun(@(x,y) sprintf('%s\n%.1f V/m', x, y), measTable.Timestamp, measTable.FieldValue, 'UniformOutput', false);
                geoTableMeas = table2geotable(measTable);
                rgbMapping   = imageUtil.getRGB(hMeasPlot);
                kmlwrite(fileName, geoTableMeas, 'Name', string(1:height(geoTableMeas))', 'Description', description, 'Color', rgbMapping)
    
            case 'Route'
                description  = sprintf('%s - %s', char(measTable.Timestamp(1)), char(measTable.Timestamp(end)));    
                kmlwriteline(fileName, measTable.Latitude, measTable.Longitude, 'Name', 'Route', 'Description', description', 'Color', 'red', 'LineWidth', 3)
        end

    catch ME
        status = false;
        msgError = ME.message;
    end
end