classdef dockStationInfo_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure           matlab.ui.Figure
        GridLayout         matlab.ui.container.GridLayout
        StationPanel       matlab.ui.container.GridLayout
        StationPanelGrid   matlab.ui.container.Panel
        StationGrid        matlab.ui.container.GridLayout
        Station            matlab.ui.control.HTML
        optNotes           matlab.ui.control.TextArea
        optNotesLabel      matlab.ui.control.Label
        Reason             matlab.ui.control.DropDown
        ReasonLabel        matlab.ui.control.Label
        NextSelection      matlab.ui.control.Image
        PreviousSelection  matlab.ui.control.Image
        btnClose           matlab.ui.control.Image
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

            idxStation = selectedStation(app);
            updateForm(app, idxStation)
        end

        %-----------------------------------------------------------------%
        function [idxStation, idxRow] = selectedStation(app)
            idxRow     = app.callingApp.UITable.Selection(1);
            idxStation = app.callingApp.UITable.UserData(idxRow);
        end

        %-----------------------------------------------------------------%
        function updateForm(app, idxStation)
            app.Station.HTMLSource = auxApp.stationInfo.htmlCode_StationInfo(app.mainApp.stationTable, idxStation, app.mainApp.rfDataHub);
            app.Reason.Value       = char(app.mainApp.stationTable.("Justificativa")(idxStation));
            app.optNotes.Value     = app.mainApp.stationTable.("Observações"){idxStation};
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
        function TypeValueChanged(app, event)
            
            newReason      = app.Reason.Value;
            newObservation = textFormatGUI.cellstr2TextField(app.optNotes.Value);
            CallingMainApp(app, 'StationTableValueChanged', true, true, newReason, newObservation)

            idxStation = selectedStation(app);
            updateForm(app, idxStation)
            
        end

        % Image clicked function: NextSelection, PreviousSelection
        function PreviousProductImageClicked(app, event)
            
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
                app.UIFigure.Position = [100 100 480 360];
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
            app.StationPanel.ColumnWidth = {22, 22, '1x'};
            app.StationPanel.RowHeight = {'1x', 17, 22, 17, 44, 22};
            app.StationPanel.ColumnSpacing = 5;
            app.StationPanel.RowSpacing = 5;
            app.StationPanel.Layout.Row = 2;
            app.StationPanel.Layout.Column = [1 2];
            app.StationPanel.BackgroundColor = [0.9804 0.9804 0.9804];

            % Create PreviousSelection
            app.PreviousSelection = uiimage(app.StationPanel);
            app.PreviousSelection.ImageClickedFcn = createCallbackFcn(app, @PreviousProductImageClicked, true);
            app.PreviousSelection.Tooltip = {'Navega para o produto anterior'};
            app.PreviousSelection.Layout.Row = 6;
            app.PreviousSelection.Layout.Column = 1;
            app.PreviousSelection.ImageSource = 'Previous_32.png';

            % Create NextSelection
            app.NextSelection = uiimage(app.StationPanel);
            app.NextSelection.ImageClickedFcn = createCallbackFcn(app, @PreviousProductImageClicked, true);
            app.NextSelection.Tooltip = {'Navega para o produto posterior'};
            app.NextSelection.Layout.Row = 6;
            app.NextSelection.Layout.Column = 2;
            app.NextSelection.ImageSource = 'After_32.png';

            % Create ReasonLabel
            app.ReasonLabel = uilabel(app.StationPanel);
            app.ReasonLabel.VerticalAlignment = 'bottom';
            app.ReasonLabel.FontSize = 10;
            app.ReasonLabel.Layout.Row = 2;
            app.ReasonLabel.Layout.Column = [1 3];
            app.ReasonLabel.Text = 'Justificativa:';

            % Create Reason
            app.Reason = uidropdown(app.StationPanel);
            app.Reason.Items = {};
            app.Reason.ValueChangedFcn = createCallbackFcn(app, @TypeValueChanged, true);
            app.Reason.FontSize = 11;
            app.Reason.BackgroundColor = [1 1 1];
            app.Reason.Layout.Row = 3;
            app.Reason.Layout.Column = [1 3];
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
            app.optNotes.ValueChangedFcn = createCallbackFcn(app, @TypeValueChanged, true);
            app.optNotes.FontSize = 11;
            app.optNotes.Layout.Row = 5;
            app.optNotes.Layout.Column = [1 3];

            % Create StationPanelGrid
            app.StationPanelGrid = uipanel(app.StationPanel);
            app.StationPanelGrid.Layout.Row = 1;
            app.StationPanelGrid.Layout.Column = [1 3];

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
