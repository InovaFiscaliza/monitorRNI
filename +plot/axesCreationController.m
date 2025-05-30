function [hAxes, restoreView] = axesCreationController(hPlotPanel, appGeneral)
    hParent = tiledlayout(hPlotPanel, 1, 1, "Padding", "none", "TileSpacing", "none");

    % Eixo geográfico: MAPA
    hAxes   = plot.axes.Creation(hParent, 'Geographic', {'Basemap',  appGeneral.Plot.GeographicAxes.Basemap,  ...
                                                         'Color',    [.2, .2, .2], 'GridColor', [.5, .5, .5], ...
                                                         'UserData', struct('CLimMode', 'auto', 'Colormap', '')});

    if ismember(appGeneral.Plot.GeographicAxes.Basemap, {'darkwater', 'none'})
        hAxes.Grid = 'on';
    end

    set(hAxes.LatitudeAxis,  'TickLabels', {}, 'Color', 'none')
    set(hAxes.LongitudeAxis, 'TickLabels', {}, 'Color', 'none')
    
    geolimits(hAxes, 'auto')
    restoreView = struct('ID', 'app.UIAxes', 'xLim', hAxes.LatitudeLimits, 'yLim', hAxes.LongitudeLimits, 'cLim', 'auto');

    plot.axes.Colormap(hAxes, appGeneral.Plot.GeographicAxes.Colormap)
    plot.axes.Colorbar(hAxes, appGeneral.Plot.GeographicAxes.Colorbar)

    % Legenda
    legend(hAxes, 'Location', 'southwest', 'Color', [.94,.94,.94], 'EdgeColor', [.9,.9,.9], 'NumColumns', 4, 'LineWidth', .5, 'FontSize', 7.5, 'PickableParts', 'none')

    % Axes interactions:
    plot.axes.Interactivity.DefaultCreation(hAxes, [dataTipInteraction, zoomInteraction, panInteraction])
end