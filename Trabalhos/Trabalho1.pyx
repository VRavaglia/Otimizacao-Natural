import random
import numpy as np
import matplotlib.pyplot as plt

# Ordem de caminhos inicial aleatoria
cidades = 10
ordem = np.arange(cidades)
np.random.shuffle(ordem[1:])
ordemHat = ordem


# Pentagono com as posicoes de cada cidade

raio = 1
pentragrama = []
for i in range(0, 5):
    pentragrama.append([raio*np.cos(np.pi/2 + i*np.pi*2/5), raio*np.sin(np.pi*2.19911 + i*np.pi*2/5)])
    pentragrama.append([raio/2*np.cos(np.pi/2 + i*np.pi*2/5), raio/2*np.sin(np.pi*2.19911 + i*np.pi*2/5)])

pentragrama = np.array(pentragrama)
x = []
x = np.array(x)

N = 1e4
ordemMin = ordem
Jatual = 1e6
Jmin = Jatual
Js = []
n = 0

T0 = 1e-2
T = T0
Ts = []
Kmax = 20
distancias = []
k = 1

# O custo é a distancia total percurrida
# def J(ordem):
#     distTot = 0
#     iAnterior = 0
#     for i in ordem[1:]:
#         dist = np.linalg.norm(x[i]-x[iAnterior])
#         iAnterior = i
#         distTot += dist
        
#     dist = np.linalg.norm(x[i]-x[0])
#     distTot += dist
#     return distTot


# # Simulated Annealing
# while k < Kmax:
#     n += 1
    
#     # Troca duas cidades de ordem de maneira aleatoria, exceto a primeira que é sempre a mesma
#     idx = random.randint(1, cidades-1)
#     idx2 = random.randint(1, cidades-1) 
#     ordemHat[idx], ordemHat[idx2] = ordem[idx2], ordem[idx]
            
#     Jit = J(ordemHat)
    
#     q = np.exp((Jatual-Jit)/T)
#     r = random.uniform(0, 1)
    
#     if r < q:
#         ordem = ordemHat
#         Jatual = Jit
        
    
#     if Jit < Jmin:
#         Jmin = Jit
#         ordemMin = ordemHat   
             
#     if n % N == 0:
#         k += 1
#         T = T0/(np.log2(1 + k))

#     distancias.append(Jit)

# Visualização do resultado final
fig, ax = plt.subplots(figsize=(4, 4))
ax.scatter(pentragrama[:,0], pentragrama[:,1])
ax.scatter(0, 0)
ax.add_patch(plt.Circle((0, 0), 1, color='r', fill=False))
plt.xlim([-1.5, 1.5])
plt.ylim([-1.5, 1.5])


# for i in ordemMin[1:]:
#     plt.annotate(text=str(i-1), xy=(x[i]), xytext=(x[i-1]), color='r', arrowprops=dict(arrowstyle='->'))

# plt.annotate(text=str(9), xy=(x[0]), xytext=(x[9]), color='r', arrowprops=dict(arrowstyle='->'))
# plt.annotate(text="Distancia minima: " + str(Jmin), xy=(-0.8,1.2), xytext=(-0.8,1.2))

plt.show()