classdef (Abstract) draw

    methods (Static = true)
        %-----------------------------------------------------------------%
        function Measures(hAxes, measTable, FieldReferenceValue, generalSettings)
            if ~isempty(measTable)
                hPlot = geoscatter(hAxes, measTable.Latitude, measTable.Longitude, [], measTable.FieldValue, ...
                    'filled', 'DisplayName', 'Medidas', 'Tag', 'Measures');
                plot.datatip.Template(hPlot, "Coordinates+Level")

                idxRisk = find(measTable.FieldValue > FieldReferenceValue);
                if ~isempty(idxRisk)
                    latitudeArray  = measTable.Latitude(idxRisk);
                    longitudeArray = measTable.Longitude(idxRisk);
    
                    geoscatter(hAxes, latitudeArray, longitudeArray,                               ...
                        'Marker', '^', 'MarkerFaceColor', generalSettings.plot.riskMeasures.color, ...
                        'MarkerEdgeColor', generalSettings.plot.riskMeasures.color,                ...
                        'SizeData', generalSettings.plot.riskMeasures.size,                        ...
                        'PickableParts', 'none', 'DisplayName', sprintf('> %.0f V/m', FieldReferenceValue), 'Tag', 'RiskMeasures');
                end
            end
        end

        %-----------------------------------------------------------------%
        function Points(hAxes, refPointsTable, DisplayName, generalSettings)
            if ~isempty(refPointsTable)
                latitudeArray  = refPointsTable.Latitude;
                longitudeArray = refPointsTable.Longitude;

                hPlot = geoscatter(hAxes, latitudeArray, longitudeArray,                   ...
                    'Marker', '^', 'MarkerFaceColor', generalSettings.plot.stations.color, ...
                    'MarkerEdgeColor', generalSettings.plot.stations.color,                ...
                    'SizeData', generalSettings.plot.stations.size, 'DisplayName', DisplayName, 'Tag', 'Points');
                plot.datatip.Template(hPlot, "Coordinates")
            end
        end

        %-----------------------------------------------------------------%
        function SelectedPoint(hAxes, selectedPointTable, generalSettings, callinAppTag)
            % (a) Ponto selecionado
            pointLatitude   = selectedPointTable.Latitude;
            pointLongitude  = selectedPointTable.Longitude;

            switch callinAppTag
                case {'auxApp.winMonitoringPlan',  'auxApp.winMonitoringPlan_exported'}
                    DIST_km     = generalSettings.context.MONITORINGPLAN.maxMeasurementDistanceKm;
                    pointID     = sprintf('Estação nº %d', selectedPointTable.("Estação"));
                    displayName = 'Maior nível em torno da estação';

                case {'auxApp.winExternalRequest', 'auxApp.winExternalRequest_exported'}
                    DIST_km     = generalSettings.context.EXTERNALREQUEST.maxMeasurementDistanceKm;
                    pointID     = selectedPointTable.ID{1};
                    displayName = 'Maior nível em torno do ponto';
            end

            hPlot = geoscatter(hAxes, pointLatitude, pointLongitude,      ...
                'Marker',          '^',                                   ...
                'MarkerFaceColor', generalSettings.plot.selectedStation.color, ...
                'MarkerEdgeColor', generalSettings.plot.selectedStation.color, ...
                'SizeData',        generalSettings.plot.selectedStation.size,  ...
                'DisplayName',     pointID,                               ...
                'Tag',             'SelectedPoint');
            plot.datatip.Template(hPlot, "Coordinates")

            % (b) Círculo entorno do ponto
            drawcircle(hAxes,                                              ...
                'Position',        [pointLatitude, pointLongitude],        ...
                'Radius',          km2deg(DIST_km),                        ...
                'Color',           generalSettings.plot.circleRegion.color,     ...
                'FaceAlpha',       generalSettings.plot.circleRegion.faceAlpha, ...
                'EdgeAlpha',       generalSettings.plot.circleRegion.edgeAlpha, ...
                'FaceSelectable',  0, 'InteractionsAllowed', 'none',       ...
                'Tag',            'SelectedPoint');

            % (c) Maior nível em torno do ponto
            maxFieldValue      = selectedPointTable.maxFieldValue;
            if maxFieldValue > 0
                maxFieldLatitude   = selectedPointTable.maxFieldLatitude;
                maxFieldLongitude  = selectedPointTable.maxFieldLongitude;

                geoscatter(hAxes, maxFieldLatitude, maxFieldLongitude, maxFieldValue, ...
                    'Marker',          'square',                                      ...
                    'MarkerFaceColor', generalSettings.plot.fieldPeak.color,               ...
                    'SizeData',        generalSettings.plot.fieldPeak.size,                ...
                    'DisplayName',     displayName,                                   ...
                    'PickableParts',   'none',                                        ...
                    'Tag',             'SelectedPoint');
            end

            % Zoom automático em torno do ponto
            if generalSettings.plot.selectedStation.automaticZoom
                ReferenceDistance_km = generalSettings.plot.selectedStation.automaticZoomFactor * DIST_km;
                plot.zoom(hAxes, pointLatitude, pointLongitude, ReferenceDistance_km)
            end
        end
    end
end

