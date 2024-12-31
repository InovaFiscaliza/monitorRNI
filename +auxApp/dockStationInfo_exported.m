classdef dockStationInfo_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        GridLayout              matlab.ui.container.GridLayout
        StationPanel            matlab.ui.container.GridLayout
        NextSelection           matlab.ui.control.Image
        PreviousSelection       matlab.ui.control.Image
        LocationPanel           matlab.ui.container.Panel
        LocationPanelGrid       matlab.ui.container.GridLayout
        Longitude               matlab.ui.control.NumericEditField
        LongitudeLabel          matlab.ui.control.Label
        Latitude                matlab.ui.control.NumericEditField
        LatitudeLabel           matlab.ui.control.Label
        LocationLabelGrid       matlab.ui.container.GridLayout
        LocationEditionCancel   matlab.ui.control.Image
        LocationEditionConfirm  matlab.ui.control.Image
        LocationEditionMode     matlab.ui.control.Image
        LocationRefresh         matlab.ui.control.Image
        LocationLabel           matlab.ui.control.Label
        optNotes                matlab.ui.control.TextArea
        optNotesLabel           matlab.ui.control.Label
        Reason                  matlab.ui.control.DropDown
        ReasonLabel             matlab.ui.control.Label
        StationPanelGrid        matlab.ui.container.Panel
        StationGrid             matlab.ui.container.GridLayout
        Station                 matlab.ui.control.HTML
        btnClose                matlab.ui.control.Image
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        Container
        isDocked = true

        mainApp     % winRNI
        callingApp  % winMonitoringPlan | winMonitoringPlan_exported
    end
    
    
    methods (Access = private)
        %-----------------------------------------------------------------%
        function initialValues(app)
            app.Reason.Items = categories(app.mainApp.stationTable.("Justificativa"));
            updateForm(app)
        end

        %-----------------------------------------------------------------%
        function updateForm(app, varargin)
            if isempty(varargin)
                idxStation = selectedStation(app);
            else
                idxStation = varargin{1};
            end

            updateFormValues(app, idxStation)
            updateFormLayout(app, idxStation)
        end
        
        %-----------------------------------------------------------------%
        function updateFormValues(app, idxStation)
            app.Station.HTMLSource = auxApp.stationInfo.htmlCode_StationInfo(app.mainApp.stationTable, idxStation, app.mainApp.rfDataHub);
            app.Reason.Value       = char(app.mainApp.stationTable.("Justificativa")(idxStation));
            app.optNotes.Value     = app.mainApp.stationTable.("Observações"){idxStation};

            set(app.Latitude,  'Value', app.mainApp.stationTable.("Latitude")(idxStation),  'UserData', app.mainApp.stationTable.("Latitude")(idxStation))
            set(app.Longitude, 'Value', app.mainApp.stationTable.("Longitude")(idxStation), 'UserData', app.mainApp.stationTable.("Longitude")(idxStation))            
        end

        %-----------------------------------------------------------------%
        function updateFormLayout(app, idxStation)
            % Identifica se ocorreu alteração nas coordenadas geográficas:
            if (app.mainApp.stationTable.("Lat")(idxStation)  ~= app.mainApp.stationTable.("Latitude")(idxStation)) || ...
               (app.mainApp.stationTable.("Long")(idxStation) ~= app.mainApp.stationTable.("Longitude")(idxStation))
                app.LocationRefresh.Visible = 1;
            else
                app.LocationRefresh.Visible = 0;
            end

            updateLocationPanelLayout(app, 'off')
        end

        %-----------------------------------------------------------------%
        function updateLocationPanelLayout(app, editionStatus)
            arguments
                app 
                editionStatus char {mustBeMember(editionStatus, {'on', 'off'})}
            end

            hEditFields = findobj(app.LocationPanelGrid.Children, '-not', 'Type', 'uilabel');            

            switch editionStatus
                case 'on'
                    set(app.LocationEditionMode, 'ImageSource', 'Edit_32Filled.png', 'UserData', true)
                    set(hEditFields, 'Editable', true)
                    
                    app.LocationLabelGrid.ColumnWidth(end-1:end) = {16,16};
                    app.LocationEditionConfirm.Enable = 1;
                    app.LocationEditionCancel.Enable  = 1;

                case 'off'
                    set(app.LocationEditionMode, 'ImageSource', 'Edit_32.png', 'UserData', false)
                    set(hEditFields, 'Editable', false)

                    app.LocationLabelGrid.ColumnWidth(end-1:end) = {0,0};
                    app.LocationEditionConfirm.Enable = 0;
                    app.LocationEditionCancel.Enable  = 0;
            end
        end

        %-----------------------------------------------------------------%
        function [idxStation, idxRow] = selectedStation(app)
            idxRow     = app.callingApp.UITable.Selection(1);
            idxStation = app.callingApp.UITable.UserData(idxRow);
        end

        %-----------------------------------------------------------------%
        function CallingMainApp(app, callType, updateFlag, returnFlag, varargin)
            appBackDoor(app.callingApp, app, callType, updateFlag, returnFlag, varargin{:})
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, callingApp)
            
            app.mainApp     = callingApp.mainApp;
            app.callingApp  = callingApp;
            
            initialValues(app)
            
        end

        % Callback function: UIFigure, btnClose
        function closeFcn(app, event)
            
            CallingMainApp(app, 'CLOSE', false, false)
            delete(app)
            
        end

        % Value changed function: Reason, optNotes
        function FormValueChanged(app, event)
            
            switch event.Source
                case {app.Reason, app.optNotes}
                    newReason    = app.Reason.Value;
                    newOptNote   = textFormatGUI.cellstr2TextField(app.optNotes.Value);
                    CallingMainApp(app, 'StationTableValueChanged: ReasonOrNote', true, true, newReason, newOptNote)

                case {app.LocationRefresh, app.LocationEditionConfirm}
                    if isequal(app.Latitude.Value,  app.Latitude.UserData) && ...
                       isequal(app.Longitude.Value, app.Longitude.UserData)
                        return
                    end

                    newLatitude  = app.Latitude.Value;
                    newLongitude = app.Longitude.Value;
                    CallingMainApp(app, 'StationTableValueChanged: Location', true, true, newLatitude, newLongitude)
            end
            
            updateForm(app)
            
        end

        % Image clicked function: LocationEditionCancel, 
        % ...and 3 other components
        function LocationEditionModeCallbacks(app, event)
            
            switch event.Source
                case app.LocationRefresh
                    idxStation = selectedStation(app);
                    app.Latitude.Value  = app.mainApp.stationTable.("Lat")(idxStation);
                    app.Longitude.Value = app.mainApp.stationTable.("Long")(idxStation);

                    FormValueChanged(app, struct('Source', event.Source))

                case app.LocationEditionMode
                    app.LocationEditionMode.UserData = ~app.LocationEditionMode.UserData;
                    if app.LocationEditionMode.UserData
                        updateLocationPanelLayout(app, 'on')
                        LocationValueChanged(app, struct('Source', event.Source))
                    else
                        updateLocationPanelLayout(app, 'off')
                    end

                case app.LocationEditionConfirm
                    FormValueChanged(app, struct('Source', event.Source))

                case app.LocationEditionCancel
                    updateForm(app)
            end

        end

        % Value changed function: Latitude, Longitude
        function LocationValueChanged(app, event)
            
            switch event.Source
                case app.LocationEditionMode
                    focus(app.Latitude)
                case app.Latitude
                    focus(app.Longitude)
                case app.Longitude
                    focus(app.LocationEditionConfirm)
            end

        end

        % Image clicked function: NextSelection, PreviousSelection
        function UITableSelectionChanged(app, event)
            
            idxStations = app.callingApp.UITable.UserData;
            [~, idxSelectedRow] = selectedStation(app);
            idxMaxRow = height(app.callingApp.UITable.Data);

            switch event.Source
                case app.PreviousSelection
                    idxNewRowSelection = idxSelectedRow - 1;
                case app.NextSelection
                    idxNewRowSelection = idxSelectedRow + 1;
            end

            if idxNewRowSelection < 1
                idxNewRowSelection = idxMaxRow;
            elseif idxNewRowSelection > idxMaxRow
                idxNewRowSelection = 1;
            end

            CallingMainApp(app, 'UITableSelectionChanged', true, true, idxNewRowSelection)
            updateForm(app, idxStations(idxNewRowSelection))

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app, Container)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            if isempty(Container)
                app.UIFigure = uifigure('Visible', 'off');
                app.UIFigure.AutoResizeChildren = 'off';
                app.UIFigure.Position = [100 100 540 440];
                app.UIFigure.Name = 'monitorRNI';
                app.UIFigure.Icon = 'icon_48.png';
                app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeFcn, true);

                app.Container = app.UIFigure;

            else
                if ~isempty(Container.Children)
                    delete(Container.Children)
                end

                app.UIFigure  = ancestor(Container, 'figure');
                app.Container = Container;
                app.isDocked  = true;
            end

            % Create GridLayout
            app.GridLayout = uigridlayout(app.Container);
            app.GridLayout.ColumnWidth = {'1x', 30};
            app.GridLayout.RowHeight = {30, '1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.BackgroundColor = [0.902 0.902 0.902];

            % Create btnClose
            app.btnClose = uiimage(app.GridLayout);
            app.btnClose.ScaleMethod = 'none';
            app.btnClose.ImageClickedFcn = createCallbackFcn(app, @closeFcn, true);
            app.btnClose.Tag = 'Close';
            app.btnClose.Layout.Row = 1;
            app.btnClose.Layout.Column = 2;
            app.btnClose.ImageSource = 'Delete_12SVG.svg';

            % Create StationPanel
            app.StationPanel = uigridlayout(app.GridLayout);
            app.StationPanel.ColumnWidth = {22, 22, '1x', 1, 212};
            app.StationPanel.RowHeight = {'1x', 22, 22, 22, 61, 22};
            app.StationPanel.ColumnSpacing = 5;
            app.StationPanel.RowSpacing = 5;
            app.StationPanel.Layout.Row = 2;
            app.StationPanel.Layout.Column = [1 2];
            app.StationPanel.BackgroundColor = [0.9804 0.9804 0.9804];

            % Create StationPanelGrid
            app.StationPanelGrid = uipanel(app.StationPanel);
            app.StationPanelGrid.Layout.Row = 1;
            app.StationPanelGrid.Layout.Column = [1 5];

            % Create StationGrid
            app.StationGrid = uigridlayout(app.StationPanelGrid);
            app.StationGrid.ColumnWidth = {'1x'};
            app.StationGrid.RowHeight = {'1x'};
            app.StationGrid.Padding = [0 0 0 0];
            app.StationGrid.BackgroundColor = [1 1 1];

            % Create Station
            app.Station = uihtml(app.StationGrid);
            app.Station.Layout.Row = 1;
            app.Station.Layout.Column = 1;

            % Create ReasonLabel
            app.ReasonLabel = uilabel(app.StationPanel);
            app.ReasonLabel.VerticalAlignment = 'bottom';
            app.ReasonLabel.FontSize = 10;
            app.ReasonLabel.Layout.Row = 2;
            app.ReasonLabel.Layout.Column = [1 5];
            app.ReasonLabel.Text = 'Justificativa:';

            % Create Reason
            app.Reason = uidropdown(app.StationPanel);
            app.Reason.Items = {};
            app.Reason.ValueChangedFcn = createCallbackFcn(app, @FormValueChanged, true);
            app.Reason.FontSize = 11;
            app.Reason.BackgroundColor = [1 1 1];
            app.Reason.Layout.Row = 3;
            app.Reason.Layout.Column = [1 5];
            app.Reason.Value = {};

            % Create optNotesLabel
            app.optNotesLabel = uilabel(app.StationPanel);
            app.optNotesLabel.VerticalAlignment = 'bottom';
            app.optNotesLabel.FontSize = 10;
            app.optNotesLabel.Layout.Row = 4;
            app.optNotesLabel.Layout.Column = [1 3];
            app.optNotesLabel.Text = 'Observações:';

            % Create optNotes
            app.optNotes = uitextarea(app.StationPanel);
            app.optNotes.ValueChangedFcn = createCallbackFcn(app, @FormValueChanged, true);
            app.optNotes.FontSize = 11;
            app.optNotes.Layout.Row = 5;
            app.optNotes.Layout.Column = [1 3];

            % Create LocationLabelGrid
            app.LocationLabelGrid = uigridlayout(app.StationPanel);
            app.LocationLabelGrid.ColumnWidth = {'1x', 16, 16, 16, 16};
            app.LocationLabelGrid.RowHeight = {'1x'};
            app.LocationLabelGrid.ColumnSpacing = 5;
            app.LocationLabelGrid.Padding = [0 0 0 0];
            app.LocationLabelGrid.Layout.Row = 4;
            app.LocationLabelGrid.Layout.Column = 5;
            app.LocationLabelGrid.BackgroundColor = [1 1 1];

            % Create LocationLabel
            app.LocationLabel = uilabel(app.LocationLabelGrid);
            app.LocationLabel.VerticalAlignment = 'bottom';
            app.LocationLabel.FontSize = 10;
            app.LocationLabel.Layout.Row = 1;
            app.LocationLabel.Layout.Column = 1;
            app.LocationLabel.Text = 'Local de instalação:';

            % Create LocationRefresh
            app.LocationRefresh = uiimage(app.LocationLabelGrid);
            app.LocationRefresh.ImageClickedFcn = createCallbackFcn(app, @LocationEditionModeCallbacks, true);
            app.LocationRefresh.Visible = 'off';
            app.LocationRefresh.Tooltip = {'Retorna à informação inicial'; '(extraída da tabela de referência)'};
            app.LocationRefresh.Layout.Row = 1;
            app.LocationRefresh.Layout.Column = 2;
            app.LocationRefresh.VerticalAlignment = 'bottom';
            app.LocationRefresh.ImageSource = 'Refresh_18.png';

            % Create LocationEditionMode
            app.LocationEditionMode = uiimage(app.LocationLabelGrid);
            app.LocationEditionMode.ImageClickedFcn = createCallbackFcn(app, @LocationEditionModeCallbacks, true);
            app.LocationEditionMode.Tooltip = {'Habilita painel de edição'};
            app.LocationEditionMode.Layout.Row = 1;
            app.LocationEditionMode.Layout.Column = 3;
            app.LocationEditionMode.VerticalAlignment = 'bottom';
            app.LocationEditionMode.ImageSource = 'Edit_32.png';

            % Create LocationEditionConfirm
            app.LocationEditionConfirm = uiimage(app.LocationLabelGrid);
            app.LocationEditionConfirm.ImageClickedFcn = createCallbackFcn(app, @LocationEditionModeCallbacks, true);
            app.LocationEditionConfirm.Enable = 'off';
            app.LocationEditionConfirm.Tooltip = {'Confirma edição'};
            app.LocationEditionConfirm.Layout.Row = 1;
            app.LocationEditionConfirm.Layout.Column = 4;
            app.LocationEditionConfirm.VerticalAlignment = 'bottom';
            app.LocationEditionConfirm.ImageSource = 'Ok_32Green.png';

            % Create LocationEditionCancel
            app.LocationEditionCancel = uiimage(app.LocationLabelGrid);
            app.LocationEditionCancel.ImageClickedFcn = createCallbackFcn(app, @LocationEditionModeCallbacks, true);
            app.LocationEditionCancel.Enable = 'off';
            app.LocationEditionCancel.Tooltip = {'Cancela edição'};
            app.LocationEditionCancel.Layout.Row = 1;
            app.LocationEditionCancel.Layout.Column = 5;
            app.LocationEditionCancel.VerticalAlignment = 'bottom';
            app.LocationEditionCancel.ImageSource = 'Delete_32Red.png';

            % Create LocationPanel
            app.LocationPanel = uipanel(app.StationPanel);
            app.LocationPanel.Layout.Row = 5;
            app.LocationPanel.Layout.Column = 5;

            % Create LocationPanelGrid
            app.LocationPanelGrid = uigridlayout(app.LocationPanel);
            app.LocationPanelGrid.RowHeight = {17, 22};
            app.LocationPanelGrid.RowSpacing = 5;
            app.LocationPanelGrid.Padding = [10 10 10 5];
            app.LocationPanelGrid.BackgroundColor = [1 1 1];

            % Create LatitudeLabel
            app.LatitudeLabel = uilabel(app.LocationPanelGrid);
            app.LatitudeLabel.VerticalAlignment = 'bottom';
            app.LatitudeLabel.FontSize = 10;
            app.LatitudeLabel.Layout.Row = 1;
            app.LatitudeLabel.Layout.Column = 1;
            app.LatitudeLabel.Text = 'Latitude:';

            % Create Latitude
            app.Latitude = uieditfield(app.LocationPanelGrid, 'numeric');
            app.Latitude.Limits = [-90 90];
            app.Latitude.ValueDisplayFormat = '%.6f';
            app.Latitude.ValueChangedFcn = createCallbackFcn(app, @LocationValueChanged, true);
            app.Latitude.Editable = 'off';
            app.Latitude.FontSize = 11;
            app.Latitude.Layout.Row = 2;
            app.Latitude.Layout.Column = 1;

            % Create LongitudeLabel
            app.LongitudeLabel = uilabel(app.LocationPanelGrid);
            app.LongitudeLabel.VerticalAlignment = 'bottom';
            app.LongitudeLabel.FontSize = 10;
            app.LongitudeLabel.Layout.Row = 1;
            app.LongitudeLabel.Layout.Column = 2;
            app.LongitudeLabel.Text = 'Longitude:';

            % Create Longitude
            app.Longitude = uieditfield(app.LocationPanelGrid, 'numeric');
            app.Longitude.Limits = [-180 180];
            app.Longitude.ValueDisplayFormat = '%.6f';
            app.Longitude.ValueChangedFcn = createCallbackFcn(app, @LocationValueChanged, true);
            app.Longitude.Editable = 'off';
            app.Longitude.FontSize = 11;
            app.Longitude.Layout.Row = 2;
            app.Longitude.Layout.Column = 2;

            % Create PreviousSelection
            app.PreviousSelection = uiimage(app.StationPanel);
            app.PreviousSelection.ImageClickedFcn = createCallbackFcn(app, @UITableSelectionChanged, true);
            app.PreviousSelection.Tooltip = {'Navega para o produto anterior'};
            app.PreviousSelection.Layout.Row = 6;
            app.PreviousSelection.Layout.Column = 1;
            app.PreviousSelection.ImageSource = 'Previous_32.png';

            % Create NextSelection
            app.NextSelection = uiimage(app.StationPanel);
            app.NextSelection.ImageClickedFcn = createCallbackFcn(app, @UITableSelectionChanged, true);
            app.NextSelection.Tooltip = {'Navega para o produto posterior'};
            app.NextSelection.Layout.Row = 6;
            app.NextSelection.Layout.Column = 2;
            app.NextSelection.ImageSource = 'After_32.png';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = dockStationInfo_exported(Container, varargin)

            % Create UIFigure and components
            createComponents(app, Container)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            if app.isDocked
                delete(app.Container.Children)
            else
                delete(app.UIFigure)
            end
        end
    end
end
