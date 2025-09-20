function [axesType, axesXLabel, axesYLabel, axesYScale] = TypeMapping(plotNamesPerAxes)

    axesType   = {};
    axesXLabel = {};
    axesYLabel = {};
    axesYScale = {};

    for ii = 1:numel(plotNamesPerAxes)
        plotNames = strsplit(plotNamesPerAxes{ii}, '+');

        switch plotNames{1}
            case {'DriveTest', ...
                  'Stations',  ...
                  'DriveTestRoute'}
                axesType{ii}   = 'Geographic';
                axesXLabel{ii} = '';
                axesYLabel{ii} = '';
                axesYScale{ii} = '';

            case {'ChannelPower', ...
                  'RFLink'}
                axesType{ii}   = 'Cartesian';
                axesXLabel{ii} = '';
                axesYLabel{ii} = '';
                axesYScale{ii} = '';
            
            otherwise
                error('Unexpected plotName %s', plotNamesPerAxes{ii})
        end
    end

end