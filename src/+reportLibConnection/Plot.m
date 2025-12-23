classdef (Abstract) Plot

    methods (Static = true)
        %-----------------------------------------------------------------%
        function imgFileName = Controller(reportInfo, analyzedData, imgSettings)
            arguments
                reportInfo
                analyzedData
                imgSettings
            end

            generalSettings = reportInfo.Settings;
            measTable       = analyzedData.InfoSet.measTable;
            refPointsTable  = analyzedData.InfoSet.stationTable;

            % Container
            hFigure    = reportInfo.App.UIFigure;
            hContainer = findobj(hFigure, 'Tag', 'reportGeneratorContainer');
            if isempty(hContainer)
                hContainer = reportLibConnection.Plot.ContainerCreation(hFigure);
            end

            if ~isempty(hContainer.Children)
                delete(hContainer.Children)
            end

            % Cria eixos de acordo com estabelecido no JSON.
            tiledPos     = 1;
            tiledSpan    = str2double(strsplit(imgSettings.Layout, ':'));

            axesParent   = tiledlayout(hContainer, sum(tiledSpan), 1, "Padding", "tight", "TileSpacing", "tight");           
            [axesType,   ...
             axesXLabel, ...
             axesYLabel, ...
             axesYScale] = plot.axes.TypeMapping({imgSettings.Name});

            for ii = 1:numel(axesType)
                xLabelFlag  = true;
                
                switch axesType{ii}
                    case 'Geographic'
                        hAxes = plot.axes.Creation(axesParent, 'Geographic',  {'Basemap',  generalSettings.Report.Basemap, ...
                                                                               'Color',    [.2, .2, .2], 'GridColor', [.5, .5, .5]});

                        if ismember(generalSettings.Plot.GeographicAxes.Basemap, {'darkwater', 'none'})
                            hAxes.Grid = 'on';
                        end
                    
                        set(hAxes.LatitudeAxis,  'TickLabels', {}, 'Color', 'none')
                        set(hAxes.LongitudeAxis, 'TickLabels', {}, 'Color', 'none')
                        
                        geolimits(hAxes, 'auto')
                    
                        plot.axes.Colormap(hAxes, generalSettings.Plot.GeographicAxes.Colormap)
                        plot.axes.Colorbar(hAxes, generalSettings.Plot.GeographicAxes.Colorbar)

                        legend(hAxes, 'Location', 'southwest', 'Color', [.94,.94,.94], 'EdgeColor', [.9,.9,.9], 'NumColumns', 4, 'LineWidth', .5, 'FontSize', 7.5, 'PickableParts', 'none')

                    case 'Cartesian'
                        hAxes = plot.axes.Creation(axesParent, 'Cartesian', {'XColor', [.15,.15,.15], 'YColor', [.15,.15,.15]});
                        if (numel(imgSettings) > 1) && (ii < numel(imgSettings)) && any(strcmp(axesType(ii+1:end), 'Cartesian'))
                            xLabelFlag = false;
                        end
                end
                hAxes.Layout.Tile     = tiledPos;
                hAxes.Layout.TileSpan = [tiledSpan(ii) 1];
            
                % PLOT
                plotNames = strsplit(imgSettings(ii).Name, '+');
                for plotTag = plotNames
                    switch plotTag{1}
                        case 'DriveTest'
                            plot.draw.Measures(hAxes, measTable, generalSettings.MonitoringPlan.FieldValue, generalSettings);
                            geolimits(hAxes, hAxes.LatitudeLimits, hAxes.LongitudeLimits)
                            plot.draw.Points(hAxes, refPointsTable, 'Estações de referência PM-RNI', generalSettings)

                        case 'ChannelPower'
                            % ...                          
    
                        case 'Route'
                            % ...
                    end
                end
                
                % POST-PLOT
                %plot.axes.StackingOrder.execute(hAxes, tempBandObj.Context)
                switch axesType{ii}
                    case 'Geographic'
                        % Força renderização do basemap usando função waitfor
                        % customizada, evitando, assim, o risco de parar a
                        % execução (no caso de uso da MATLAB built-in waitfor).

                        % Protegido por bloco try/catch porque o basemap não 
                        % é informação essencial do plot e esse approach de usar 
                        % o objeto "TileReader" é algo não documentado, sujeito 
                        % a alterações pela Mathworks.
                        try
                            tilesController = struct(hAxes).BasemapManager.TileReader;
                            if ~tilesController.MapTileAcquired && tilesController.NumMapTilesInCache == 0
                                % waitfor(tilesController, 'NumMapTilesInCache')
                                matlab.waitfor(tilesController, 'NumMapTilesInCache', @(x) x~=0, .100, 10)
                            end
                        catch
                        end

                    case 'Cartesian'
                        % xAxes
                        hAxes.XLim = tempBandObj.xLim;

                        if xLabelFlag
                            xlabel(hAxes, axesXLabel{ii})
                        else
                            hAxes.XTickLabel = {};
                            xlabel(hAxes, '')
                        end

                        % yAxes
                        if ~isempty(axesYScale{ii})
                            hAxes.YScale = axesYScale{ii};
                        end

                        if ~isempty(axesYLabel{ii})
                            ylabel(hAxes, axesYLabel{ii})
                        end
                end
                tiledPos = tiledPos+tiledSpan(ii);
            end
            drawnow

            % Espera renderizar e salva a imagem...
            defaultFilename = appEngine.util.DefaultFileName(generalSettings.fileFolder.tempPath, class.Constants.appName, reportInfo.Function.var_Issue);
            imgFileName     = sprintf('%s.%s', defaultFilename, generalSettings.Report.Image.Format);
            if ~ismember(reportInfo.Model.Version, {'final', 'Definitiva'})
                imgFileName = replace(imgFileName, 'Image', '~Image');
            end
            
            exportgraphics(hContainer, imgFileName, 'ContentType', 'image', 'Resolution', generalSettings.Report.Image.Resolution)
            
            while true
                pause(1)
                if isfile(imgFileName)
                    break
                end
            end
        end

        %-----------------------------------------------------------------%
        function hContainer = ContainerCreation(hFigure)
            xWidth     = class.Constants.windowSize(1);
            yHeight    = class.Constants.windowSize(2);    
            hContainer = uipanel(hFigure, AutoResizeChildren='off',          ...
                                          Position=[100 100 xWidth yHeight], ...
                                          BorderType='none',                 ...
                                          BackgroundColor=[0 0 0],           ...
                                          Visible=0,                         ...
                                          Tag="reportGeneratorContainer");
        end
    end

end