using LinearAlgebra
using Plots
using TimerOutputs
using Waveforms
using Distributed;
using ProgressMeter
using Profile
using Dagger

#Definiçoes

const cidades = 50
const raioBase = 0.8506508

const fatorNormalizacao = 1
const raioPentagono = (raioBase .+ 0.2*trianglewave.(10*pi.*(0:cidades-1)./(cidades)) .+ 0.2)
const pos = raioPentagono.*[cos.(2 .* pi .* (0:cidades-1) ./ cidades) sin.(2 .* pi .* (0:cidades-1) ./ cidades)];

const ordemOtima = 1:cidades

using LinearAlgebra

custosTemp = zeros(Float32, cidades, cidades)

for i = 1:cidades
    for j in 1:cidades
        custosTemp[i, j] = norm(pos[i, :]-pos[j, :])
    end
end

const custos = custosTemp;

function J(ordem)
    distTot = 0.0
    for i = 2:cidades
        distTot += custos[ordem[i], ordem[i-1]]    
    end
    
    distTot += custos[ordem[end], ordem[1]]
    
    return distTot
end

function J(ordem, cIdx = 0)
    distTot = 0.0
    for i = 2:cidades
        if cIdx == 0
            distTot += custos[ordem[i], ordem[i-1]]
        else    
            distTot += custos[ordem[cIdx, i], ordem[cIdx, i-1]]
        end
    end
    
    if cIdx == 0
        distTot += custos[ordem[end], ordem[1]]
    else
        distTot += custos[ordem[cIdx, end], ordem[cIdx, 1]]
    end
    
    return distTot
end

function PMX(p1, p2, child)
    csize = length(p1)
    child .= 0
    
    #1
    
    i1 = rand(1:csize)
    i2 = rand(1:csize)

    if i1 > i2
        i1, i2 = i2, i1
    end
    
    # explicito para reduzir alocacoes
    for i = i1:i2
        child[i] = p1[i]
    end
    
    #2
    for i = i1:i2
        rep2 = p2[i]
        found = false
        
        # usar findall()[1] gera muitas alocacoes
        rep_idx2 = findFirst(p2, rep2)
        
        # usar rep2 in child[i1:i2] gera muitas alocacoes
        # por conta do slice [i1:i2]
        for j = i1:i2
            if rep2 == child[j]
                found = true
                break
            end
        end
        while(!found)
            rep1 = p1[rep_idx2]
            rep_idx1 = findFirst(p1, rep1)
            
            if(rep_idx1 < i1 || rep_idx1 > i2)
                child[rep_idx1] = rep2
                found = true
            else
                rep_idx2 = findFirst(p2, rep1)
            end
        end
    end    
    #3
    
    for i = 1:csize
        if child[i] == 0
            child[i] = p2[i]
        end
    end
    
    return child
end

function findFirst(input, element)
    idx = 0
    for el in input
        idx += 1
        if element == el
            return idx
        end
    end
end

function reverse(A, i1, i2)
    max = length(A)
    for i = i1:i2
        A[i] = A[max-i]
    end
end

#SR
function SR(lista, min, proximidade)
    taxa = 0
    rodadas = length(lista)
    
    for l in lista
        if(abs(min - l) <= proximidade)
            taxa += 1/rodadas
        end
    end
    
    return taxa*100
end

using Statistics

#MBF
function MBF(lista, min)   
    return min/mean(lista)
end

#AES
function AES(execsPorIt)
    taxa = 0
    rodadas = 0
    
    for exec in execsPorIt
        if exec > 0
            taxa += exec
            rodadas += 1
        end
    end
    if rodadas > 0
        taxa = taxa/rodadas
    end
    return taxa
end

function SGA_cidades(Xs, gens, k, Jmin, mu, meme, depth, maxSearch)
    parents = Array{Int16}(undef, k, cidades)
    xhat = Array{Int16}(undef, cidades)
    child = Array{Int16}(undef, cidades)
    p1 = Array{Int16}(undef, cidades)
    p2 = Array{Int16}(undef, cidades)
    Jhist = Array{Float32}(undef, gens)
    execsHist = 0
    scores = Array{Float32}(undef, mu)
    for gen = 1:gens
        # Pontuacao  
        for i = 1:mu
            scores[i] = J(Xs, i)
            execsHist += 1
        end
        minIdx = argmin(scores)
        Jhist[gen] = scores[minIdx]
        if(abs(Jmin - scores[minIdx]) < 0.001)
#             println("Minimo encontrado");
            Jhist[gen:end] .= Jmin
            return scores[minIdx], Xs[minIdx, :], Jhist, execsHist
        end
        
        # Selecao dos Pais
        topIdx = sortperm(scores, rev=false)

        # gerava alocacoes
        # copy!(parents, Xs[topIdx[1:k], :])

        for i = 1:k
            for j = 1:cidades
                parents[i, j] = Xs[topIdx[i], j]
            end
        end
        
        
        # Crossover
        for i = 1:mu
            # gerava alocacoes
            # copy!(p1, parents[rand(1:k), :])
            # copy!(p2, parents[rand(1:k), :])

            r1 = rand(1:k)
            r2 = rand(1:k)
            for j = 1:cidades
                p1[j] = parents[r1, j]
                p2[j] = parents[r2, j]
            end
            
            Xs[i, :] = PMX(p1, p2, child)
        end
        
        # Mutacao
        for i = 1:mu
            i1 = rand(1:cidades)
            i2 = rand(1:cidades)
            if i1 > i2
                i1, i2 = i2, i1
            end
            
            Xs[i, i1:i2] = Xs[i, i2:-1:i1]
            
        end
        
        # Memetico
        if meme
            for i = 1:mu
                for depths = 1:depth
                    Jold = J(Xs, i)
                    execsHist += 1;
                    dJ = 1
                    searches = 0
                    while dJ >=0 && searches < maxSearch
                        for j = 1:cidades 
                            xhat[j] = Xs[i, j]
                        end
                        i1 = rand(1:cidades)
                        i2 = rand(1:cidades)
                        if i1 > i2
                            i1, i2 = i2, i1
                        end
                        xhat[i1:i2] = xhat[i2:-1:i1]
                        dJ = J(xhat) - Jold
                        execsHist += 1;
                        searches += 1
                    end
                    if dJ < 0
                        for j = 1:cidades 
                            Xs[i, j] = xhat[j]
                        end
                    end
                end
            end
        end
    end
    # Pontuacao
    minIdx = argmin(scores)
#     println("Minimo nao encontrado:");
    execsHist = -1
    return scores[minIdx], Xs[minIdx, :], Jhist, execsHist
end

const mus = [25, 50, 75, 100, 125]
const gens = [100, 200, 300, 400, 500]
const ks = [2, 4, 6, 8, 10]
const runs = [100]
const depths = [1, 2, 3, 4, 5]
const maxSearches = [10, 50, 100, 150, 200]
grid = false

# const mus = [100]
# const gens = [300]
# const ks = [2, 4, 6]
# const runs = [30]

function idx2grid(idx, meme = false)
    its = 0
    for mu in mus
        for gen in gens
            for k in ks
                for run in runs
                    if meme
                        for depth in depths
                            for maxS in maxSearches
                                its += 1
                                if its == idx
                                    return mu, gen, k, run, depth, maxS
                                end
                            end
                        end
                    else
                        its += 1
                        if its == idx
                            return mu, gen, k, run, 0, 0
                        end
                    end
                end
            end
        end
    end
    return its
end

const maxIts = idx2grid(0)

using ProgressMeter
using Random

Jmin = J(ordemOtima)
mu = 125
gen = 100
k = 2
run = 10
meme = true
depth = 3
maxSearch = 10

allJmin = zeros(run)
allExecs = zeros(run)
allDistancias = zeros(gen, run)

@time begin
@showprogress for j = 1:run
    Random.seed!(j);
    
    Xs = Array{Int16}(undef, mu, cidades)
    for i = 1:mu
        Xs[i, :] = shuffle(1:cidades)
    end
     
    time = @elapsed begin
        minS, ~, Jhist, ~ = SGA_cidades(Xs, gen, k, Jmin, mu, meme, depth, maxSearch);
    end
    allDistancias[:, j] = Jhist
    allJmin[j] = minS  
end
end