    function ProgressoBarraStatus = Progressbar_Files(app, File_Sondas)            
            % Criar o diálogo de progresso
            d = uiprogressdlg(app.UIFigure, 'Title', 'Aguarde a importação dos dados das medições!', ...
                'Message', 'Opening the application', ...
                'Indeterminate', 'off', ... % Para ter uma barra de progresso que aumenta gradualmente
                'Value', 0);  % Valor inicial do progresso
            
            % % Ler o conteúdo do arquivo para uma string
            % fileContent = fileread(File_Sondas);
            % 
            % % Encontrar as ocorrências da palavra-chave
            % occurrences = numel(strfind(fileContent, sprintf('\n')));

            % % Encontrar as ocorrências da palavra-chave 'PAUSED'
            % occurrences_PAUSED = numel(strfind(fileContent, 'PAUSED'));
            % 
            % % Total de linahs com iformações úteis no arquivo
            % occurrences = occurrences - occurrences_PAUSED;
                
            StepsProgress = 100;
            % Número do Sterps do Progressbar
            % numOccurrences = round(occurrences/StepsProgress);
            numOccurrences = round(StepsProgress);
            ProgressoBarraStatus = {numOccurrences d}; 
end

% function Cont_Step = Comp_Cont_Step(contsteps, count_ocorrencia, corrent_Step, Arq_Num, Total_Files, numOccurrences, d)
%             corrent_Step = corrent_Step + 1;
%             StepsProgress = 100;
%             progress = corrent_Step / StepsProgress;
% 
%             % Atualiza o progresso na barra
%             d.Value = progress;
%             d.Message = sprintf('Lendo %dº de %d Arquivo(s) / Progresso: %d%%', ...
%                 Arq_Num, Total_Files, round(progress * 100));
% 
%             % Atualiza a contagem de ocorrências
%             count_ocorrencia = count_ocorrencia + numOccurrences;
% 
%             Cont_Step = {count_ocorrencia d corrent_Step};
% end