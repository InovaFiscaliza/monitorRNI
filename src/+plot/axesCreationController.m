function [hAxes, restoreView] = axesCreationController(hPlotPanel, generalSettings)
    hParent = tiledlayout(hPlotPanel, 1, 1, "Padding", "none", "TileSpacing", "none");

    % Eixo geográfico: MAPA
    hAxes   = plot.axes.Creation(hParent, 'Geographic', {'Basemap',  generalSettings.plot.geographicAxes.basemap,  ...
                                                         'Color',    [.2, .2, .2], 'GridColor', [.5, .5, .5], ...
                                                         'UserData', struct('CLimMode', 'auto', 'Colormap', '')});

    if ismember(generalSettings.plot.geographicAxes.basemap, {'darkwater', 'none'})
        hAxes.Grid = 'on';
    end

    set(hAxes.LatitudeAxis,  'TickLabels', {}, 'Color', 'none')
    set(hAxes.LongitudeAxis, 'TickLabels', {}, 'Color', 'none')
    
    geolimits(hAxes, 'auto')
    restoreView = struct('ID', 'app.UIAxes', 'xLim', hAxes.LatitudeLimits, 'yLim', hAxes.LongitudeLimits, 'cLim', 'auto');

    plot.axes.Colormap(hAxes, generalSettings.plot.geographicAxes.colormap)
    plot.axes.Colorbar(hAxes, generalSettings.plot.geographicAxes.colorbar)

    % Legenda
    legend(hAxes, 'Location', 'southwest', 'Color', [.94,.94,.94], 'EdgeColor', [.9,.9,.9], 'NumColumns', 4, 'LineWidth', .5, 'FontSize', 7.5, 'PickableParts', 'none')

    % Axes interactions:
    plot.axes.Interactivity.DefaultCreation(hAxes, [dataTipInteraction, zoomInteraction, panInteraction])
end