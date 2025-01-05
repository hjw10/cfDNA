dir1='/public/workspace/stu21230110/cfDNA'

#GEO数据库找到项目编号，再到ENA数据库找数据下载
#将SRR_Acc_List.txt放进来
prefetch -O $dir1/data/ --option-file SRR_Acc_List.txt
#sra转fastq
mkdir 1.files
fastq-dump --gzip --split-files ../data/SRR*/*
#处理前做一次fastqc
for file in *.fastq.gz
do
fastpc $file &
done
wait
fastqc .

#下载数据
for file in `cat ../accessions.txt` 
do 
  wget -c ftp://download.big.ac.cn/gsa3/CRA000617/${file}/${file}_f1.fastq.gz
  wget -c ftp://download.big.ac.cn/gsa3/CRA000617/${file}/${file}_r2.fastq.gz
  echo "finished"
done

#fastp处理
mkdir 3.claendata
in_dir=2.data
out_dir=3.cleandata
for name in `cat accessions.txt` 
do
  echo $name
	echo `date`
	echo "** Starting to clean $name **"
	time fastp -i $in_dir/$name'_f1.fastq.gz' -o $out_dir/$name'_1.fastq.gz' \
        -I $in_dir/$name'_r2.fastq.gz' -O $out_dir/$name'_2.fastq.gz' \
		  -w 10
done

#下载参考基因组
wget https://ftp.ensembl.org/pub/release-111/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
#下载注释文件
wget https://ftp.ensembl.org/pub/release-111/gtf/homo_sapiens/Homo_sapiens.GRCh38.111.gtf.gz
gunzip Homo_sapiens.GRCh38.111.gtf.gz
gunzip Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz

#bwa构建索引
time bwa index Homo_sapiens.GRCh38.dna.primary_assembly.fa

#bwa mem 比对
mkdir 4.map
for name in `cat accessions.txt` 
do
  echo $name
	echo `date`
	echo "** Starting to map $name **"
	time bwa mem -t 20 -o $dir1/4.map/${name}.bwa.pe.sam $dir1/Homo_sapiens.GRCh38.dna.primary_assembly.fa \
  $dir1/3.cleandata/$name'_1.fastq.gz' $dir1/3.cleandata/$name'_2.fastq.gz'
done

#sam转bam
mkdir 5.bam
for name in `cat accessions.txt` 
do
  echo $name
	echo `date`
	echo "** Starting to view $name **"
	samtools view -b -@ 8 -o $dir1/5.bam/${name}.bwa.pe.bam \
    $dir1/4.map/${name}.bwa.pe.sam
done

#fixmate
mkdir 6.fixmate
for name in `cat accessions.txt` 
do
    echo $name
	echo `date`
	echo "** Starting to fixmate $name **"
	samtools fixmate -r -m -@ 10 $dir1/5.bam/${name}.bwa.pe.bam $dir1/6.fixmate/${name}.bwa.pe.fixmate.bam
done

#排序
mkdir 7.sort
for name in `cat accessions.txt` 
do
    echo $name
	echo `date`
	echo "** Starting to sort $name **"
	samtools sort -@ 10 -o $dir1/7.sort/${name}.bwa.pe.fixmate.sort.bam $dir1/6.fixmate/${name}.bwa.pe.fixmate.bam
done

#去重复
mkdir 8.markdup
for name in `cat accessions.txt` 
do
    echo $name
	echo `date`
	echo "** Starting to markdup $name **"
	samtools markdup -r -@ 10 $dir1/7.sort/${name}.bwa.pe.fixmate.sort.bam $dir1/8.markdup/${name}.bwa.pe.fixmate.sort.rmdup.bam
done