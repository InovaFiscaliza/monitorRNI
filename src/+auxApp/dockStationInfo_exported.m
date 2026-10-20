classdef dockStationInfo_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        GridLayout              matlab.ui.container.GridLayout
        EditableFieldsPanel     matlab.ui.container.Panel
        EditableFieldsGrid      matlab.ui.container.GridLayout
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
        EditableFieldsLabel     matlab.ui.control.Label
        StationPanel            matlab.ui.container.Panel
        StationGrid             matlab.ui.container.GridLayout
        Station                 matlab.ui.control.Label
        SummaryLabel            matlab.ui.control.Label
        NextSelection           matlab.ui.control.Image
        PreviousSelection       matlab.ui.control.Image
        Title                   matlab.ui.control.Label
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        Role = 'secondaryDockApp'
    end


    properties (Access = public)
        %-----------------------------------------------------------------%
        Container
        isDocked = true
        mainApp
        callingApp
        jsBackDoor
    end


    properties (Access = private)
        %-----------------------------------------------------------------%
        inputArgs
    end
    
    
    methods (Access = private)
        %-----------------------------------------------------------------%
        function jsBackDoor_Customizations(app)
            drawnow

            appName = class.Constants.appName;
            elToModify = {
                app.Station;
                app.LocationRefresh;
                app.LocationEditionMode;
                app.LocationEditionConfirm;
                app.LocationEditionCancel
            };
            ui.CustomizationBase.getElementsDataTag(elToModify);

            try
                ui.TextView.startup(app.jsBackDoor, app.Station, appName, struct('class', {{'textview--borderless', 'textview--wordbreak'}}));
            catch
            end

            try
                sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', { ...
                    struct('appName', appName, 'dataTag', app.LocationRefresh.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Retorna aos valores constantes em base', 'zIndex', 901)), ...
                    struct('appName', appName, 'dataTag', app.LocationEditionMode.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Habilita ou desabilita edição de características da estação', 'zIndex', 901)), ...
                    struct('appName', appName, 'dataTag', app.LocationEditionConfirm.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Confirma edição', 'zIndex', 901)), ...
                    struct('appName', appName, 'dataTag', app.LocationEditionCancel.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Cancela edição', 'zIndex', 901)) ...
                });
            catch
            end

            app.LocationEditionMode.UserData.status = false;
        end

        %-----------------------------------------------------------------%
        function initialValues(app)
            app.Reason.Items = categories(app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Justificativa"));
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
            app.Station.Text   = util.HtmlTextGenerator.StationInfo(app.mainApp.projectData.modules.MONITORINGPLAN.stationTable, idxStation, app.mainApp.rfDataHub);
            app.Reason.Value   = char(app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Justificativa")(idxStation));
            app.optNotes.Value = app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Observações"){idxStation};

            set(app.Latitude,  'Value', app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Latitude")(idxStation),  'UserData', app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Latitude")(idxStation))
            set(app.Longitude, 'Value', app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Longitude")(idxStation), 'UserData', app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Longitude")(idxStation))            
        end

        %-----------------------------------------------------------------%
        function updateFormLayout(app, idxStation)
            % Identifica se ocorreu alteração nas coordenadas geográficas:
            if (app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Lat")(idxStation)  ~= app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Latitude")(idxStation)) || ...
               (app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Long")(idxStation) ~= app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Longitude")(idxStation))
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
                    app.LocationEditionMode.ImageSource = 'Edit_32Filled.png';
                    app.LocationEditionMode.UserData.status = true;
                    set(hEditFields, 'Editable', true)
                    
                    app.LocationLabelGrid.ColumnWidth(end-1:end) = {18, 18};
                    app.LocationEditionConfirm.Enable = 1;
                    app.LocationEditionCancel.Enable  = 1;

                case 'off'
                    app.LocationEditionMode.ImageSource = 'Edit_32.png';
                    app.LocationEditionMode.UserData.status = false;
                    set(hEditFields, 'Editable', false)

                    app.LocationLabelGrid.ColumnWidth(end-1:end) = {0,0};
                    app.LocationEditionConfirm.Enable = 0;
                    app.LocationEditionCancel.Enable  = 0;
            end
        end

        %-----------------------------------------------------------------%
        function [idxStation, idxRow] = selectedStation(app)
            idxRow     = app.callingApp.UITable.Selection;
            idxStation = app.callingApp.UITable.UserData(idxRow);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp, callingApp, context)
                        
            try
                appEngine.boot(app, app.Role, mainApp, callingApp)

                app.inputArgs = struct('context', context);    
                jsBackDoor_Customizations(app)
                initialValues(app)
                
            catch ME
                ui.Dialog(app.UIFigure, 'error', getReport(ME), 'CloseFcn', @(~,~)closeFcn(app));
            end
            
        end

        % Close request function: UIFigure
        function closeFcn(app, event)
            
            delete(app)
            
        end

        % Value changed function: Reason, optNotes
        function onFormValueChanged(app, event)
            
            switch event.Source
                case {app.optNotes, app.Reason}
                    newOptNote = textFormatGUI.cellstr2TextField(app.optNotes.Value);
                    newReason  = app.Reason.Value;

                    if event.Source == app.optNotes && ismember(newOptNote, {'', '-'})
                        app.optNotes.Value = event.PreviousValue;
                        return
                    end
                    
                    ipcMainMatlabCallsHandler(app.mainApp, app, 'onStationInfoChanged', 'MONITORINGPLAN', newReason, newOptNote)

                case {app.LocationRefresh, app.LocationEditionConfirm}
                    if isequal(app.Latitude.Value,  app.Latitude.UserData) && ...
                       isequal(app.Longitude.Value, app.Longitude.UserData)
                        return
                    end

                    newLatitude  = app.Latitude.Value;
                    newLongitude = app.Longitude.Value;
                    
                    ipcMainMatlabCallsHandler(app.mainApp, app, 'onStationCoordinatesEdited', 'MONITORINGPLAN', newLatitude, newLongitude)
            end
            
            updateForm(app)
            
        end

        % Image clicked function: LocationEditionCancel, 
        % ...and 3 other components
        function onLocationEditionModeChanged(app, event)
            
            switch event.Source
                case app.LocationRefresh
                    idxStation = selectedStation(app);
                    app.Latitude.Value  = app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Lat")(idxStation);
                    app.Longitude.Value = app.mainApp.projectData.modules.MONITORINGPLAN.stationTable.("Long")(idxStation);

                    onFormValueChanged(app, struct('Source', event.Source))

                case app.LocationEditionMode
                    app.LocationEditionMode.UserData.status = ~app.LocationEditionMode.UserData.status;
                    if app.LocationEditionMode.UserData.status
                        updateLocationPanelLayout(app, 'on')
                        onLocationInfoChanged(app, struct('Source', event.Source))
                    else
                        updateLocationPanelLayout(app, 'off')
                        updateForm(app)
                    end

                case app.LocationEditionConfirm
                    onFormValueChanged(app, struct('Source', event.Source))

                case app.LocationEditionCancel
                    updateForm(app)
            end

        end

        % Value changed function: Latitude, Longitude
        function onLocationInfoChanged(app, event)
            
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
        function onStationSelectionChanged(app, event)
            
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

            ipcMainMatlabCallsHandler(app.mainApp, app, 'onStationSelectionChanged', 'MONITORINGPLAN', idxNewRowSelection)
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
                app.UIFigure.Position = [100 100 540 464];
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
                if ~isprop(Container, 'RunningAppInstance')
                    addprop(app.Container, 'RunningAppInstance');
                end
                app.Container.RunningAppInstance = app;
                app.isDocked  = true;
            end

            % Create GridLayout
            app.GridLayout = uigridlayout(app.Container);
            app.GridLayout.ColumnWidth = {442, 24, 24};
            app.GridLayout.RowHeight = {40, 22, 160, 22, 160};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;
            app.GridLayout.Padding = [20 20 20 20];
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create Title
            app.Title = uilabel(app.GridLayout);
            app.Title.VerticalAlignment = 'top';
            app.Title.FontSize = 15;
            app.Title.FontColor = [0 0.4471 0.7412];
            app.Title.Layout.Row = 1;
            app.Title.Layout.Column = 1;
            app.Title.Interpreter = 'html';
            app.Title.Text = {'<b>Justificar ausência de medição</b>'; '<font style="color: gray; font-size: 10px;">Informe o motivo da ausência de medição e, se aplicável, o local de instalação da estação</font>'};

            % Create PreviousSelection
            app.PreviousSelection = uiimage(app.GridLayout);
            app.PreviousSelection.ImageClickedFcn = createCallbackFcn(app, @onStationSelectionChanged, true);
            app.PreviousSelection.Layout.Row = 1;
            app.PreviousSelection.Layout.Column = 2;
            app.PreviousSelection.ImageSource = 'chevron-left.svg';

            % Create NextSelection
            app.NextSelection = uiimage(app.GridLayout);
            app.NextSelection.ImageClickedFcn = createCallbackFcn(app, @onStationSelectionChanged, true);
            app.NextSelection.Layout.Row = 1;
            app.NextSelection.Layout.Column = 3;
            app.NextSelection.ImageSource = 'chevron-right.svg';

            % Create SummaryLabel
            app.SummaryLabel = uilabel(app.GridLayout);
            app.SummaryLabel.VerticalAlignment = 'bottom';
            app.SummaryLabel.FontSize = 11;
            app.SummaryLabel.FontWeight = 'bold';
            app.SummaryLabel.FontColor = [0 0.4471 0.7412];
            app.SummaryLabel.Layout.Row = 2;
            app.SummaryLabel.Layout.Column = [1 3];
            app.SummaryLabel.Text = 'Informações da estação selecionada';

            % Create StationPanel
            app.StationPanel = uipanel(app.GridLayout);
            app.StationPanel.Layout.Row = 3;
            app.StationPanel.Layout.Column = [1 3];

            % Create StationGrid
            app.StationGrid = uigridlayout(app.StationPanel);
            app.StationGrid.ColumnWidth = {'1x'};
            app.StationGrid.RowHeight = {'1x'};
            app.StationGrid.Padding = [0 0 0 0];
            app.StationGrid.BackgroundColor = [1 1 1];

            % Create Station
            app.Station = uilabel(app.StationGrid);
            app.Station.VerticalAlignment = 'top';
            app.Station.WordWrap = 'on';
            app.Station.FontSize = 11;
            app.Station.Layout.Row = 1;
            app.Station.Layout.Column = 1;
            app.Station.Interpreter = 'html';
            app.Station.Text = '';

            % Create EditableFieldsLabel
            app.EditableFieldsLabel = uilabel(app.GridLayout);
            app.EditableFieldsLabel.VerticalAlignment = 'bottom';
            app.EditableFieldsLabel.FontSize = 11;
            app.EditableFieldsLabel.FontWeight = 'bold';
            app.EditableFieldsLabel.FontColor = [0 0.4471 0.7412];
            app.EditableFieldsLabel.Layout.Row = 4;
            app.EditableFieldsLabel.Layout.Column = [1 3];
            app.EditableFieldsLabel.Text = 'Justificativa';

            % Create EditableFieldsPanel
            app.EditableFieldsPanel = uipanel(app.GridLayout);
            app.EditableFieldsPanel.AutoResizeChildren = 'off';
            app.EditableFieldsPanel.Layout.Row = 5;
            app.EditableFieldsPanel.Layout.Column = [1 3];

            % Create EditableFieldsGrid
            app.EditableFieldsGrid = uigridlayout(app.EditableFieldsPanel);
            app.EditableFieldsGrid.ColumnWidth = {'1x', '1x', 212};
            app.EditableFieldsGrid.RowHeight = {17, 22, 22, '1x'};
            app.EditableFieldsGrid.RowSpacing = 5;
            app.EditableFieldsGrid.BackgroundColor = [1 1 1];

            % Create ReasonLabel
            app.ReasonLabel = uilabel(app.EditableFieldsGrid);
            app.ReasonLabel.VerticalAlignment = 'bottom';
            app.ReasonLabel.FontSize = 10;
            app.ReasonLabel.Layout.Row = 1;
            app.ReasonLabel.Layout.Column = [1 3];
            app.ReasonLabel.Text = 'Motivo:';

            % Create Reason
            app.Reason = uidropdown(app.EditableFieldsGrid);
            app.Reason.Items = {};
            app.Reason.ValueChangedFcn = createCallbackFcn(app, @onFormValueChanged, true);
            app.Reason.FontSize = 11;
            app.Reason.BackgroundColor = [1 1 1];
            app.Reason.Layout.Row = 2;
            app.Reason.Layout.Column = [1 3];
            app.Reason.Value = {};

            % Create optNotesLabel
            app.optNotesLabel = uilabel(app.EditableFieldsGrid);
            app.optNotesLabel.VerticalAlignment = 'bottom';
            app.optNotesLabel.FontSize = 10;
            app.optNotesLabel.Layout.Row = 3;
            app.optNotesLabel.Layout.Column = 1;
            app.optNotesLabel.Text = 'Observações:';

            % Create optNotes
            app.optNotes = uitextarea(app.EditableFieldsGrid);
            app.optNotes.ValueChangedFcn = createCallbackFcn(app, @onFormValueChanged, true);
            app.optNotes.FontSize = 11;
            app.optNotes.Layout.Row = 4;
            app.optNotes.Layout.Column = [1 2];

            % Create LocationLabelGrid
            app.LocationLabelGrid = uigridlayout(app.EditableFieldsGrid);
            app.LocationLabelGrid.ColumnWidth = {'1x', 18, 18, 0, 0};
            app.LocationLabelGrid.RowHeight = {'1x'};
            app.LocationLabelGrid.ColumnSpacing = 5;
            app.LocationLabelGrid.Padding = [0 0 0 0];
            app.LocationLabelGrid.Layout.Row = 3;
            app.LocationLabelGrid.Layout.Column = 3;
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
            app.LocationRefresh.ScaleMethod = 'none';
            app.LocationRefresh.ImageClickedFcn = createCallbackFcn(app, @onLocationEditionModeChanged, true);
            app.LocationRefresh.Visible = 'off';
            app.LocationRefresh.Layout.Row = 1;
            app.LocationRefresh.Layout.Column = 2;
            app.LocationRefresh.VerticalAlignment = 'bottom';
            app.LocationRefresh.ImageSource = 'Refresh_18.png';

            % Create LocationEditionMode
            app.LocationEditionMode = uiimage(app.LocationLabelGrid);
            app.LocationEditionMode.ImageClickedFcn = createCallbackFcn(app, @onLocationEditionModeChanged, true);
            app.LocationEditionMode.Layout.Row = 1;
            app.LocationEditionMode.Layout.Column = 3;
            app.LocationEditionMode.VerticalAlignment = 'bottom';
            app.LocationEditionMode.ImageSource = 'Edit_32.png';

            % Create LocationEditionConfirm
            app.LocationEditionConfirm = uiimage(app.LocationLabelGrid);
            app.LocationEditionConfirm.ImageClickedFcn = createCallbackFcn(app, @onLocationEditionModeChanged, true);
            app.LocationEditionConfirm.Enable = 'off';
            app.LocationEditionConfirm.Layout.Row = 1;
            app.LocationEditionConfirm.Layout.Column = 4;
            app.LocationEditionConfirm.VerticalAlignment = 'bottom';
            app.LocationEditionConfirm.ImageSource = 'Ok_32Green.png';

            % Create LocationEditionCancel
            app.LocationEditionCancel = uiimage(app.LocationLabelGrid);
            app.LocationEditionCancel.ImageClickedFcn = createCallbackFcn(app, @onLocationEditionModeChanged, true);
            app.LocationEditionCancel.Enable = 'off';
            app.LocationEditionCancel.Layout.Row = 1;
            app.LocationEditionCancel.Layout.Column = 5;
            app.LocationEditionCancel.VerticalAlignment = 'bottom';
            app.LocationEditionCancel.ImageSource = 'Delete_32Red.png';

            % Create LocationPanel
            app.LocationPanel = uipanel(app.EditableFieldsGrid);
            app.LocationPanel.AutoResizeChildren = 'off';
            app.LocationPanel.Layout.Row = 4;
            app.LocationPanel.Layout.Column = 3;

            % Create LocationPanelGrid
            app.LocationPanelGrid = uigridlayout(app.LocationPanel);
            app.LocationPanelGrid.ColumnWidth = {90, 90};
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
            app.Latitude.ValueChangedFcn = createCallbackFcn(app, @onLocationInfoChanged, true);
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
            app.Longitude.ValueChangedFcn = createCallbackFcn(app, @onLocationInfoChanged, true);
            app.Longitude.Editable = 'off';
            app.Longitude.FontSize = 11;
            app.Longitude.Layout.Row = 2;
            app.Longitude.Layout.Column = 2;

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
