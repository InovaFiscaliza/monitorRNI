# monitorRNI  

O monitorRNI é uma ferramenta de pós-processamento de dados gerados em campanhas de medição da exposição humana a campos elétricos, no âmbito do Plano de Monitoração de Radiação Não Ionizante (PM-RNI).  
- Leitura de arquivos brutos de medidas gerados pelas sondas WaveControl MonitEM e Narda 8059.  
- Identificação de medições no entorno de pontos de interesse, com geração de plots georreferenciados da rota.
- Geração de relatórios e exportação de arquivos de resultados em vários formatos (.html, .xlsx e .kml). 

<img width="1920" height="1032" src="https://github.com/user-attachments/assets/49f24d00-bd68-40b2-b942-b98175ebc738" />

#### COMPATIBILIDADE  
A ferramenta foi desenvolvida em **MATLAB** e possui uma versão *desktop*, que pode ser utilizada em ambiente offline, e uma versão *webapp*, acessível na intranet. O monitorRNI é compatível com as versões mais recentes do MATLAB (ex.: *R2024a* e *R2025a*). A versão compilada — seja *desktop* ou *webapp* — é executada sobre a máquina virtual do MATLAB, o MATLAB Runtime.  

#### EXECUÇÃO NO AMBIENTE DO MATLAB  
Caso o aplicativo seja executado diretamente no MATLAB, é necessário:  
1. Clonar o presente repositório.
2. Clonar também o repositório [SupportPackages](https://github.com/InovaFiscaliza/SupportPackages), adicionando ao *path* do MATLAB as seguintes pastas deste repositório:  
```
.\src\Anatel
.\src\General
```

3. Abrir o projeto **monitorRNI.prj**.
4. Executar **winMonitorRNI.mlapp**.  

#### OUTRAS INFORMAÇÕES
🔗 [InovaFiscaliza/monitorRNI](https://anatel365.sharepoint.com/sites/InovaFiscaliza/SitePages/monitorRNI.aspx)  
