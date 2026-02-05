classdef (Abstract) ROI

    methods (Static = true)
        %-----------------------------------------------------------------%
        function hROI = draw(roiType, hAxes, customProp)
            arguments
                roiType char {mustBeMember(roiType, {'images.roi.Line',      ...
                                                     'images.roi.Circle',    ...
                                                     'images.roi.Rectangle', ...
                                                     'images.roi.Polygon'})}
                hAxes
                customProp cell = {}
            end
        
            defaultProp = plot.ROI.defaultProperties(roiType);
        
            switch roiType
                case 'images.roi.Line'
                    hROI = images.roi.Line(hAxes, defaultProp{:});
                case 'images.roi.Circle'
                    hROI = images.roi.Circle(hAxes, defaultProp{:});
                case 'images.roi.Rectangle'
                    hROI = images.roi.Rectangle(hAxes, defaultProp{:});
                case 'images.roi.Polygon'
                    hROI = images.roi.Polygon(hAxes, defaultProp{:});
            end
        
            if ~isempty(customProp)
                set(hROI, customProp{:})
            end
        end
        
        %-----------------------------------------------------------------%
        function defaultProp = defaultProperties(roiType)
            arguments
                roiType char {mustBeMember(roiType, {'images.roi.Line',      ...
                                                     'images.roi.Circle',    ...
                                                     'images.roi.Rectangle', ...
                                                     'images.roi.Polygon'})}
            end

            switch roiType
                case 'images.roi.Line'
                    defaultProp = {'Color', 'red',  ...
                                   'MarkerSize', 4, ...
                                   'LineWidth', 1,  ...
                                   'Deletable', 0,  ...
                                   'InteractionsAllowed', 'translate'};        
                otherwise
                    defaultProp = {'LineWidth', 1,  ...
                                   'Deletable', 0,  ...
                                   'FaceSelectable', 0};
            end
        
            if roiType == "Rectangle"
                defaultProp = [defaultProp, {'Rotatable', true}];
            end
        end

        %-----------------------------------------------------------------%
        function spec = specification(hROI)
            % Características mínimas de cada tipo de ROI para que seja
            % possível a sua reconstrução programaticamente...
            
            switch class(hROI)
                case 'images.roi.Line'
                    spec = struct('Position', round(hROI.Position, 6));
                
                case 'images.roi.Circle'
                    spec = struct('Center',   round(hROI.Center,   6), 'Radius', round(hROI.Radius, 6));
                
                case 'images.roi.Rectangle'
                    spec = struct('Position', round(hROI.Position, 6), 'RotationAngle', round(hROI.RotationAngle, 6));
                
                case 'images.roi.Polygon'
                    spec = struct('Position', round(hROI.Position, 6));

                case 'map.graphics.chart.primitive.Polygon'
                    spec = struct('Latitude',  round(struct(hROI.ShapeData).InternalData.VertexCoordinate1, 6), ...
                                  'Longitude', round(struct(hROI.ShapeData).InternalData.VertexCoordinate2), 6);
            end
        end
    end
end