classdef (Abstract) draw

    methods (Static = true)
        %-----------------------------------------------------------------%
        function Measures(hAxes, measTable, FieldReferenceValue, appGeneral)
            if ~isempty(measTable)
                hPlot = geoscatter(hAxes, measTable.Latitude, measTable.Longitude, [], measTable.FieldValue, ...
                    'filled', 'DisplayName', 'Medidas', 'Tag', 'Measures');
                plot.datatip.Template(hPlot, "Coordinates+Level")

                idxRisk = find(measTable.FieldValue > FieldReferenceValue);
                if ~isempty(idxRisk)
                    latitudeArray  = measTable.Latitude(idxRisk);
                    longitudeArray = measTable.Longitude(idxRisk);
    
                    geoscatter(hAxes, latitudeArray, longitudeArray,                          ...
                        'Marker', '^', 'MarkerFaceColor', appGeneral.Plot.RiskMeasures.Color, ...
                        'MarkerEdgeColor', appGeneral.Plot.RiskMeasures.Color,                ...
                        'SizeData', appGeneral.Plot.RiskMeasures.Size,                        ...
                        'PickableParts', 'none', 'DisplayName', sprintf('> %.0f V/m', FieldReferenceValue), 'Tag', 'RiskMeasures');
                end
            end
        end

        %-----------------------------------------------------------------%
        function Points(hAxes, refPointsTable, DisplayName, appGeneral)
            if ~isempty(refPointsTable)
                latitudeArray  = refPointsTable.Latitude;
                longitudeArray = refPointsTable.Longitude;

                hPlot = geoscatter(hAxes, latitudeArray, longitudeArray,              ...
                    'Marker', '^', 'MarkerFaceColor', appGeneral.Plot.Stations.Color, ...
                    'MarkerEdgeColor', appGeneral.Plot.Stations.Color,                ...
                    'SizeData', appGeneral.Plot.Stations.Size, 'DisplayName', DisplayName, 'Tag', 'Points');
                plot.datatip.Template(hPlot, "Coordinates")
            end
        end

        %-----------------------------------------------------------------%
        function SelectedPoint(hAxes, selectedPointTable, appGeneral, callinAppTag)
            % (a) Ponto selecionado
            pointLatitude   = selectedPointTable.Latitude;
            pointLongitude  = selectedPointTable.Longitude;

            switch callinAppTag
                case {'auxApp.winMonitoringPlan',  'auxApp.winMonitoringPlan_exported'}
                    DIST_km     = appGeneral.MonitoringPlan.Distance_km;
                    pointID     = sprintf('Estação nº %d', selectedPointTable.("Estação"));
                    displayName = 'Maior nível em torno da estação';

                case {'auxApp.winExternalRequest', 'auxApp.winExternalRequest_exported'}
                    DIST_km     = appGeneral.ExternalRequest.Distance_km;
                    pointID     = selectedPointTable.ID{1};
                    displayName = 'Maior nível em torno do ponto';
            end

            hPlot = geoscatter(hAxes, pointLatitude, pointLongitude,      ...
                'Marker',          '^',                                   ...
                'MarkerFaceColor', appGeneral.Plot.SelectedStation.Color, ...
                'MarkerEdgeColor', appGeneral.Plot.SelectedStation.Color, ...
                'SizeData',        appGeneral.Plot.SelectedStation.Size,  ...
                'DisplayName',     pointID,                               ...
                'Tag',             'SelectedPoint');
            plot.datatip.Template(hPlot, "Coordinates")

            % (b) Círculo entorno do ponto
            drawcircle(hAxes,                                              ...
                'Position',        [pointLatitude, pointLongitude],        ...
                'Radius',          km2deg(DIST_km),                        ...
                'Color',           appGeneral.Plot.CircleRegion.Color,     ...
                'FaceAlpha',       appGeneral.Plot.CircleRegion.FaceAlpha, ...
                'EdgeAlpha',       appGeneral.Plot.CircleRegion.EdgeAlpha, ...
                'FaceSelectable',  0, 'InteractionsAllowed', 'none',       ...
                'Tag',            'SelectedPoint');

            % (c) Maior nível em torno do ponto
            maxFieldValue      = selectedPointTable.maxFieldValue;
            if maxFieldValue > 0
                maxFieldLatitude   = selectedPointTable.maxFieldLatitude;
                maxFieldLongitude  = selectedPointTable.maxFieldLongitude;

                geoscatter(hAxes, maxFieldLatitude, maxFieldLongitude, maxFieldValue, ...
                    'Marker',          'square',                                      ...
                    'MarkerFaceColor', appGeneral.Plot.FieldPeak.Color,               ...
                    'SizeData',        appGeneral.Plot.FieldPeak.Size,                ...
                    'DisplayName',     displayName,                                   ...
                    'PickableParts',   'none',                                        ...
                    'Tag',             'SelectedPoint');
            end

            % Zoom automático em torno do ponto
            if appGeneral.Plot.SelectedStation.AutomaticZoom
                ReferenceDistance_km = appGeneral.Plot.SelectedStation.AutomaticZoomFactor * DIST_km;
                plot.zoom(hAxes, pointLatitude, pointLongitude, ReferenceDistance_km)
            end
        end
    end
end

