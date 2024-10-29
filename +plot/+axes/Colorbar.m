function Colorbar(hAxes, Location)
    arguments
        hAxes
        Location char {mustBeMember(Location, {'off', 'west', 'east', 'south', 'eastoutside', 'southoutside', 'westoutside'})}
    end

    switch Location
        case 'off'
            colorbar(hAxes,'off')
        otherwise
            cb = findobj(hAxes.Parent.Children, 'Type', 'colorbar');
            if ~isempty(cb)
                cb.Location = Location;
            else
                colorbar(hAxes, 'Location', Location, 'Color', 'white', 'HitTest', 'off');
            end
    end
end