filename = "C:\\Users\\penguin\\Desktop\\cfDNA\\accessions.txt"

f = open(filename,'w')
i = 471
while(i <= 653):
    line = 'CRR023' + str(i)
    f.write(line + " ")
    i += 1
f.close()

