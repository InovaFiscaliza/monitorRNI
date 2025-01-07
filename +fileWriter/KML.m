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
                Description  = arrayfun(@(x,y) sprintf('%s\n%.1f V/m', x, y), measTable.Timestamp, measTable.FieldValue, 'UniformOutput', false);
                measGEOTable = table2geotable(measTable);
                RGBMapping   = imageUtil.getRGB(hMeasPlot);
    
                kmlwrite(fileName, measGEOTable, 'Name', string(1:height(measGEOTable))', 'Description', Description, 'Color', RGBMapping)
    
            case 'Route'
                Description  = sprintf('%s - %s', char(measTable.Timestamp(1)), char(measTable.Timestamp(end)));
    
                kmlwriteline(fileName, measTable.Latitude, measTable.Longitude, 'Name', 'Route', 'Description', Description', 'Color', 'red', 'LineWidth', 3)
        end

    catch ME
        status = false;
        msgError = ME.message;
    end
end