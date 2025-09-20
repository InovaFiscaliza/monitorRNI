classdef (Abstract) Plot

    methods (Static = true)
        %-----------------------------------------------------------------%
        function imgFileName = Controller(reportInfo, analyzedData, imgSettings)
            % Container
            hFigure    = reportInfo.app.UIFigure;
            hContainer = findobj(hFigure, 'Tag', 'PlotContainer');

            if isempty(hContainer)
                hContainer = reportLibConnection.Plot.ContainerCreation(hFigure);
            end

            if ~isempty(hContainer.Children)
                delete(hContainer.Children)
            end

            % Cria eixos de acordo com estabelecido no JSON.
            tiledPos     = 1;
            tiledSpan    = [imgSettings.Layout];

            axesParent   = tiledlayout(hContainer, sum(tiledSpan), 1, "Padding", "tight", "TileSpacing", "tight");           
            [axesType,   ...
             axesXLabel, ...
             axesYLabel, ...
             axesYScale] = plot.axes.TypeMapping({imgSettings.Name});

            for ii = 1:numel(imgSettings)
                xLabelFlag  = true;
                
                switch axesType{ii}
                    case 'Geographic'
                        hAxes = plot.axes.Creation(axesParent, 'Geographic');

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
                            reportLibConnection.Plot.DriveTestPlot(hAxes, tempBandObj, idxThread, reportInfo)

                        case 'ChannelPower'
                            % ...                          
    
                        case 'Route'
                            % ...
                    end
                end
                
                % POST-PLOT
                plot.axes.StackingOrder.execute(hAxes, tempBandObj.Context)
                switch axesType{ii}
                    case 'Geographic'
                        % ...

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
            defaultFilename = appUtil.DefaultFileName(reportInfo.General.TempPath, sprintf('Image_ID%d', specData(idxThread).RelatedFiles.ID(1)), -1);
            imgFileName     = sprintf('%s.%s', defaultFilename, reportInfo.General.Image.Format);
            if ~ismember(reportInfo.Model.Version, {'final', 'Definitiva'})
                imgFileName = replace(imgFileName, 'Image', '~Image');
            end
            
            exportgraphics(hContainer, imgFileName, 'ContentType', 'image', 'Resolution', reportInfo.General.Image.Resolution)
            
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
                                          Tag="PlotContainer");
        end
    end

end