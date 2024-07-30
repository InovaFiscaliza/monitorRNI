classdef (Abstract) Annotation

    methods (Static = true)
        %-----------------------------------------------------------------%
        function annotationTable = AnnotationTable()
            annotationTable = table('Size', [0, 7],                          ...
                                    'VariableTypes', repmat({'cell'}, 1, 7), ...
                                    'VariableNames', {'ID', 'Data/Hora', 'Computador', 'Usuário', 'Homologação', 'Atributo', 'Valor'});
        end


        %-----------------------------------------------------------------%
        function annotationTable = read(varargin)
            fileOperation = varargin{1};
            fileFullPath  = varargin{2};

            switch fileOperation
                case 'Local'                    
                    annotationTable = readtable(fileFullPath, 'VariableNamingRule', 'preserve');

                case 'Server'
                    URL = varargin{3};
                    try
                        websave(fileFullPath, URL)
                        load(fileFullPath, 'annotationTable')
                    catch
                        annotationTable = class.Annotation.AnnotationTable();
                    end
            end
        end


        %-----------------------------------------------------------------%
        function msgError = AnnotationDataUpload(varargin)
            uploadType          = varargin{1};
            annotationTempTable = varargin{2};

            try
                switch uploadType
                    case 'Offline'
                        annotationTableFileFullPath = varargin{3};
                        writetable(annotationTempTable, annotationTableFileFullPath, 'WriteVariableNames', false, ...
                                                                                     'WriteMode', 'append',       ...
                                                                                     'AutoFitWidth', false)
    
                    case 'Online'
                        serverRepository = varargin{3};                        
                        webwrite(serverRepository, annotationTempTable)
                end

                msgError = '';
            catch ME
                msgError = ME.message;
            end
        end


        %-----------------------------------------------------------------%
        function annotationTempTable = addRow(annotationTable, annotationTempTable, varargin)
            % VERIFICAR SE JÁ EXISTE NA CONCATENAÇÃO DE ANNOTATIONTABLE E
            % ANNOTATIONTEMPTABLE.

            % VERIFICAR SE UUID É ÚNICO... VERIFICAR SE O HOM/ATT/VALUE SÃO
            % IGUAIS...

            annotationTempTable(end+1,:) = varargin;
        end
        

        % % We only want to reconstruct the zip file if the mcrinstaller
        % % has been updated since the last build
        % needsUpdate = true;
        % dirData = dir(mcrinstallerfilelocation);
        % 
        % %treat the timestamps as strings
        % timestamp = num2str(dirData.datenum);
        % 
        % needsUpdate = ~strcmp(old_timestamp,timestamp);
    end
end