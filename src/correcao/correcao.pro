pro correcao,file1,file2,file3
;entrada:
	;file1 = arquivo .save com os dados do CARPET
	;file2 = arquivo .save com os dados meteorológicos
	;file3 = arquivo . save com os dados do SABER
;saída:
	;arquivo .save com os dados corrigidos pela pressao e temperatura
;****************************************************************************************************************************
;---> ABRINDO ARQUIVOS
print,'====================================================================================================================='
print,'AGUARDE ...'
print,'====================================================================================================================='
;---> ABRINDO OS ARQUIVOS COM OS DADOS
restore, file1
n=n_elements(t)
di1=di & df1=df
up1=up & low1=low & tel1=tel
restore,file2
di2=di & df2=df & time_met=time & temp_met=temp & pre_met=pre
restore,file3
di3=di & df3=df & time_saber=time & temp_saber=temp
;---> TIRANDO VALORES PERDIDOS
p=where(pre_met le 0.) 
if p(0) ne -1 then begin 
  pre_met(p)=!values.f_nan
  temp_met(p)=!values.f_nan
endif
p=where(temp_met le -99)
if p(0) ne -1 then temp_met(p)=!values.f_nan
p=where(temp_saber eq -9999)
if p(0) ne -1 then temp_saber(p)=!values.f_nan
;---> AUMENTANDO VETOR TEMPO DADOS SABER
nts=n_elements(time_saber)
time_sr=rebin(time_saber-0.5,nts*24.*60.)*24.*60. ;---> Passa pra minuto
temp_sr=fltarr(nts*24.*60.,197) ;---> Passa pra minuto 
for j=0,196 do begin
   temp_pro=temp_saber(*,j)
   temp_pro=rebin(temp_pro,nts*24.*60.)
   temp_sr(*,j)=smooth(temp_pro,12.*60.,/nan,/edge) 
endfor
;---> DEIXANDO OS VETORES TEMPO DO SABER E DO CARPET COM A MESMA REFERENCIA
q=strpos(di1,' ') & data1=strmid(di1,0,q)+' 00:00:00'
d1=UTC2DOY(data1,/fract)
d3=UTC2DOY(di3,/fract)
bu=(d1-d3)*24.*60.
if bu lt 0. then begin
    print, 'ERRO ENTRE AS DATAS INICIAS: SABER E CARPET'
    print,'====================================================================================================================='
    stop
endif
ti_saber=t(0)/(60.*1000.)+bu
tf_saber=t(n-1)/(60.*1000.)+bu
;---> ENCONTRANDO A DATA CERTA NOS DADOS DO SABER
pi_saber=where(time_sr ge ti_saber) & pi_saber=pi_saber(0)
pf_saber=pi_saber+(n/120.)+1.
;pf_saber=where(time_sr ge tf_saber) & pf_saber=pf_saber(0)
if (pf_saber-pi_saber) lt (n/120.) then begin
  print, 'ERRO ENTRE AS DATAS: SABER E CARPET'
  print,'====================================================================================================================='
  stop
endif
if abs(time_sr(pf_saber)-tf_saber) gt 10. then begin
  print, 'ERRO ENTRE AS DATAS: SABER E CARPET'
  print,'====================================================================================================================='
  stop
endif
;---> PEGANDO VALORES DOS COEFICIENTES PARA CADA ALTURA
; restore,'/home/edith/Escritorio/DADOS_JOSE_CR/CORREGIR3-COMPARAR/correcao/CORR_INT_COEF.save'
restore, '/home/adriano/x-ray-lightning/src/correcao/CORR_INT_COEF.save'
up_saber=fltarr(286) & low_saber=fltarr(286) & tel_saber=fltarr(286)
;---> FAZENDO A CORRECAO USANDO DADOS DO SABER
u=0
n_int=fix(n/120.)*120.
;n_int=long(n/120.)

for i=0L,n_int-1,120 do begin
   print,i
   ;---> CALCULANDO CORRECAO PARA CADA ALTURA 
   for j=0,196 do begin
      temp_pro=temp_sr(pi_saber:pf_saber,j)
      up_saber(j)=ret_up(1,j)*(temp_pro(u)-273.15-m_temp(j))*m_up(j)*(-1)
      low_saber(j)=ret_low(1,j)*(temp_pro(u)-273.15-m_temp(j))*m_low(j)*(-1)
      tel_saber(j)=ret_tel(1,j)*(temp_pro(u)-273.15-m_temp(j))*m_tel(j)*(-1)
   endfor
   ;---> SOMANDO TODOS OS RESULTADOS
   up_total=total(up_saber,/nan)
   low_total=total(low_saber,/nan)
   tel_total=total(tel_saber,/nan)
   ;---> CORRIGINDO OS DADOS
   up(i:i+119)=up(i:i+119)+up_total
   low(i:i+119)=low(i:i+119)+low_total
   tel(i:i+119)=tel(i:i+119)+tel_total
   ;---> MOSTANDO DADOS PARA CONFERENCIA
 ;  if i eq 0 then begin
 ;    print,'SOMATORIO DAS CORRECOES PRIMEIRO PONTO'
 ;    print,'UP: '+strtrim(up_total,1)
 ;    print,'LOW: '+strtrim(low_total,1)
 ;    print,'TEL: '+strtrim(tel_total,1)
 ;    print,'====================================================================================================================='
 ;  endif 
 ;     if i eq (n-120) then begin
 ;    print,'SOMATORIO DAS CORRECOES ULTIMO PONTO'
 ;    print,'UP: '+strtrim(up_total,1)
 ;    print,'LOW: '+strtrim(low_total,1)
 ;    print,'TEL: '+strtrim(tel_total,1)
 ;    print,'====================================================================================================================='
 ;  endif 
   u=u+1
endfor

;---> FAZENDO CALCULO PARA O ULTIMO PONTO
if n_int lt n then begin
  ;--> CALCULANDO CORRECAO PARA CADA ALTURA 
  for j=0,196 do begin
     temp_pro=temp_sr(pi_saber:pf_saber,j)
     up_saber(j)=ret_up(1,j)*(temp_pro(u)-273.15-m_temp(j))*m_up(j)*(-1)
     low_saber(j)=ret_low(1,j)*(temp_pro(u)-273.15-m_temp(j))*m_low(j)*(-1)
     tel_saber(j)=ret_tel(1,j)*(temp_pro(u)-273.15-m_temp(j))*m_tel(j)*(-1)
  endfor
  print,n_int
  ;--> SOMANDO TODOS OS RESULTADOS
  up_total=total(up_saber,/nan)
  low_total=total(low_saber,/nan)
  tel_total=total(tel_saber,/nan)
  ;--> CORRIGINDO OS DADOS
  up(n_int:*)=up(n_int:*)+up_total
  low(n_int:*)=low(n_int:*)+low_total
  tel(n_int:*)=tel(n_int:*)+tel_total
endif
;---> AMPLIANDO O VETOR PRESSAO, TEMPERATURA E TEMPO
npre=(n_elements(pre_met))*3600.
pre_r=rebin(pre_met,npre)
temp_r=rebin(temp_met,npre)
time_r=rebin(time_met,npre)
;---> DEIXANDO OS VETORES TEMPO DOS MET E CARPET COM A MESMA REFERENCIA
q=strpos(di1,' ') & data1=strmid(di1,0,q)+' 00:00:00'
d1=UTC2DOY(data1,/fract)
d2=UTC2DOY(di2,/fract)
bu=(d1-d2)*24.*3600.
if bu lt 0. then begin
    print, 'ERRO ENTRES AS DATAS INICIAS: MET E CARPET'
    print,'====================================================================================================================='
    stop
endif
ti=t(0)/1000.+bu
tf=t(n-1)/1000.+bu
;---> ENCONTRANDO A DATA CERTA NOS DADOS MET
pi=where(time_r ge ti) & pi=pi(0)
pf=where(time_r ge tf) & pf=pf(0)
if (pf-pi) ne (n-1) then begin
  print, 'ERRO ENTRES AS DATAS: MET E CARPET'
  print,'====================================================================================================================='
  stop
endif
if abs(time_r(pf)-tf) gt 60 then begin
     print, 'ERRO ENTRES AS DATAS: MET E CARPET'
     print,'====================================================================================================================='
     stop
endif
time1=time_r(pi:pf)
pre1=pre_r(pi:pf)
temp1=temp_r(pi:pf)
;---> FAZENDO A CORRECAO USANDO DADOS MET
up_c=fltarr(n)
low_c=fltarr(n)
tel_c=fltarr(n)
for i=0L,n-1 do begin
   p=finite(temp1(i),/nan)
   if p eq 0 then begin
     up_c(i)=up(i)+0.0035*(pre1(i)-745.2)*96.5994+0.000779915*(temp1(i)-11.4728)*96.6882
     low_c(i)=low(i)+0.0033*(pre1(i)-745.2)*97.0833+0.000814761*(temp1(i)-11.4728)*97.3227
     tel_c(i)=tel(i)+0.0044*(pre1(i)-745.2)*31.1414+0.000963718*(temp1(i)-11.4728)*31.1729
   endif else begin
     up_c(i)=up(i)
     low_c(i)=low(i)
     tel_c(i)=tel(i)
   endelse
endfor
;---> SALVANDO ARQUIVO
di=di1 & df=df1
save,filename='C_'+strmid(file1,0,6)+'.save',up_c,low_c,tel_c,t,tres,di,df
print,'CRIADO ARQUIVO: '+'C_'+strmid(file1,0,6)+'.save'
end
