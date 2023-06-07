# Maratona de Filmes 

### Descrição
Projeto da disciplina de Super Computação do Insper

### Como rodar os arquivos
- Algoritmo sequenciais:
  - g++ -g *nome_do_arquivo.cpp* -o *nome_do_executavel*
- Algoritmo openmp:
  - g++ -fopenmp -g *nome_do_arquivo.cpp* -o *nome_do_executavel*
- Algoritmo gpu (.cu):
  - nvcc -arch=sm_70 -std=c++14 *nome_do_arquivo.cu* -o *nome_do_executavel*

### Relatório   
O relatório está disponível no arquivo relatorioFinal.ipynb, e pode ser visualizado no vscode ou no jupyter notebook. Uma versão em html também está disponível no arquivo relatorioFinal.html Além disso, dois notebook auxiliares estão disponível em geracaoResultados.ipynb e geracaoResultados_exaustiva.ipynb;

### Desenvolvedor
José Fernandes
