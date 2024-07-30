function Loop_Read_Files  = Loop_Files(app)
        % Número total de iterações
        numIterations = 100;
        
        % Criar a barra de progresso
        h = uiprogressdlg('Title', 'Progresso', 'Message', 'Iniciando o processamento...', 'Value', 0);
        
        % Loop de processamento
        for i = 1:numIterations
            % Simular algum trabalho com uma pausa
            pause(0.1); % Remove ou ajuste conforme necessário
            
            % Atualizar a barra de progresso
            h.Value = i / numIterations;
            h.Message = sprintf('Progresso: %.1f%%', (i / numIterations) * 100);
        end
        
        % Fechar a barra de progresso quando o loop termina
        delete(h);
end