classdef (Abstract) StackingOrder

    properties (Constant)
        %-----------------------------------------------------------------%
        RFDataHub = {'FilterROI', 'RFLink', 'TX', 'RX', 'Stations'}
        RFLink    = {'StationLabel', 'Station', 'Link', 'Fresnel', 'FirstObstruction', 'Footnote', 'Terrain'}
    end


    methods (Static = true)
        %-----------------------------------------------------------------%
        function execute(hAxes, clientID)
            switch clientID
                case 'RFDataHub'
                    refStackingOrder = plot.axes.StackingOrder.RFDataHub;

                case 'RFLink'
                    refStackingOrder = plot.axes.StackingOrder.RFLink;

                otherwise
                    error('Unexpected option.')
            end
            
            stackingOrderTag = arrayfun(@(x) x.Tag, hAxes.Children, 'UniformOutput', false)';

            [~, newOrderMemberIndex] = ismember(stackingOrderTag, refStackingOrder);
            [~, newOrderIndex]       = sort(newOrderMemberIndex);
        
            hAxes.Children = hAxes.Children(newOrderIndex);
        end
    end
end