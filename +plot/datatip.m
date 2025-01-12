classdef (Abstract) datatip

    methods (Static = true)
        %-----------------------------------------------------------------%
        function Template(dtParent, dtType, varargin)
            arguments
                dtParent
                dtType char {mustBeMember(dtType, {'Coordinates', ...
                                                   'Coordinates+Level'})}
            end

            arguments (Repeating)
                varargin
            end

            if isempty(dtParent)
                return
            elseif ~isprop(dtParent, 'DataTipTemplate')
                % 'images.roi.line' e 'images.roi.Rectangle' não suportam DataTip
                try
                    dt = datatip(dtParent, Visible = 'off');
                catch
                    return
                end
            end

            set(dtParent.DataTipTemplate, FontName='Calibri', FontSize=10)

            switch dtType
                case 'Coordinates'
                    dtParent.DataTipTemplate.DataTipRows(1).Label  = 'Lat:';
                    dtParent.DataTipTemplate.DataTipRows(2).Label  = 'Lon:';
                    if numel(dtParent.DataTipTemplate.DataTipRows) > 2
                        dtParent.DataTipTemplate.DataTipRows(3:end) = [];
                    end

                case 'Coordinates+Level'
                    dtParent.DataTipTemplate.DataTipRows(1).Label  = 'Lat:';
                    dtParent.DataTipTemplate.DataTipRows(2).Label  = 'Lon:';
                    dtParent.DataTipTemplate.DataTipRows(3).Label  = '';
                    dtParent.DataTipTemplate.DataTipRows(3).Format = '%0.2f V/m';
            end

            if exist('dt', 'var')
                delete(dt)
            end
        end
    end
end