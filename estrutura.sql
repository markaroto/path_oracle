/*
#********************************************************************************************************************
#* 									                                                                                *
#*                                                                                                                  *
#* SCRIPT: estrutura.sql                                                                                            *
#* DESCRIÇO: Criar um script com toda atual estrutura da instancia.                                                 *
#*                                                                                                                  *
#* VERSAO: 1.1                                                                                                      *
#*                                                                                                                  *
#* PARAMETROS: &1(caminho e nome do script de saida)                                                                *
#*                                                                  									            *
#* OUTPUT: script executavel para criar  caminhos na instancia. 	                                                *
#*                                                                                                                  *
#* ATUALIZACOES:                                                                                                    *
#*                                                                                                                  *
#********************************************************************************************************************

*/
--Definições saida do select.
SET HEADING OFF FEEDBACK OFF ECHO OFF PAGESIZE 0;
set lines 155;
-- Criação do script.
SPOOL &1;
-- corpo do script.
select '#!/bin/bash' from  dual;

--Hostname da maquina atual.
select 'host=`hostname | awk -F'||chr(39)||'.'||chr(39)|| chr(32) ||chr(39)||'{print $1}'||chr(39)||'`'||chr(10) 
||'host1=`echo $host | tr '|| chr(39)||'[:lower:]'||chr(39)||chr(32)||chr(39)||'[:upper:]'||chr(39)||'`' from dual;
-- host=`hostname | awk -F'.' '{print $1}'`
--host1=`echo $host | tr '[:lower:]' '[:upper:]'`
--variavel banco
select 'banco="'||instance_name||'";' from v$instance;


select 'script_atual="Criar_diretorio";' from dual;
--variavel diretorio

select 'PID=$$' from dual;
--variavel PID
--Criando a função gravar log.
select 'gravar_log() {' from dual;
select chr(32)||'hora=`date +%H:%M:%S`'|| chr(10)
	|| chr(32)|| chr(32)||'data_log=`date +%d-%m-%Y`'||chr(10)
	|| chr(32)|| chr(32)||'printf "%s%s%s%s%s%s%-10s%-20s%10d%s%-30s\n" ${data_log} " " ${hora} " " ${host1} " " ${banco} ${script_atual} ${PID} " - ${1}"  >> "/bkp/estrutura.log"' from dual;	
select '}' from dual;



select 
	'####------ '|| d.name || chr(10)
	||'if [ -d "'||d.valor|| '" ]; then '||chr(10)
	||chr(32)||'gravar_log "Diretorio ja existe '||d.valor||' "; '||chr(10)
	||'else'||chr(10)
	||chr(32)||'mkdir -pv "'||d.valor|| '" ;'||chr(10)
	||chr(32)||'if [ "$?" == "0" ]; then '||chr(10)
	||chr(32)||chr(32)||'gravar_log "Diretorio criado com sucesso '||d.valor||' "; '||chr(10)
	||chr(32)||chr(32)||'chown -R oracle:oinstall "'||d.valor||'" ;'||chr(10)
	||chr(32)||chr(32)||'if [ "$?" == "0" ]; then '||chr(10)
	||chr(32)||chr(32)||chr(32)||'gravar_log "Liberado as permissoes no diretorio '||d.valor||'  com sucesso";'||chr(10)
	||chr(32)||chr(32)||'else' ||chr(10)
	||chr(32)||chr(32)||chr(32)||'gravar_log "Liberado as permissoes no diretorio '||d.valor||' com error" ; '||chr(10)
	||chr(32)||chr(32)||'fi;'||chr(10)
	||chr(32)||'else' ||chr(10)
	||chr(32)||chr(32)||'gravar_log "Problema para realizar a cricao do diretorio '||d.valor||' ";'||chr(10)
	||chr(32)||'fi;'||chr(10)
	||'fi;'||chr(10)
from (
select 
    case
        when name='spfile'
            then name||' e init'
        else
            name
    end as name,
	case 
        when instr(substr(value,instr(value,'/',-1,1)+1),'.',-1,1)<>0
			then substr(value,0,instr(value,'/',-1,1)-1)
        else 
			value
    end as valor   
    --Coleta de informações do v$parameter do value /ora
	from v$parameter where value like '/ora%' and name <> 'control_files'   
UNION
select 'Data_file' as name, substr(file_name,0,instr(file_name,'/',-1,1)-1)  as valor 
	--Coleta informações data_files
	from dba_data_files
union
select 'Log_file' as name, substr(member,0,instr(member,'/',-1,1)-1) as valor 
	--Coleta informações logfile
	from V$logfile
union
select 'TEMP_FILE' as name,substr(name,0,instr(name,'/',-1,1)-1) as valor 
	--Coleta informações tempfile
	from V$TEMPFILE
union
select name as name,'$ORACLE_HOME'||substr(value,instr(value,'?',-1,1)+1)  as valor from 
	--Coleta de informações do v$parameter do value ?/
	V$parameter where value like '?/%'
union
select 'Directory '||directory_name as name,directory_path as value 
	--Coleta de informações do directors.
	from DBA_DIRECTORIES
union
select 'Control_files' as name,trim(substr(regexp_substr(str,'[^,]+',1,level),0,instr(regexp_substr(str,'[^,]+',1,level),'/',-1,1)-1)) as valor
	--Coleta local dos control_files.
	from   (select value as str from v$parameter where name='control_files') t
	connect by regexp_substr(str,'[^,]+',1,level) is not null
) d 
--Agrupa comando duplicados
group by d.valor,d.name;
--Finalizar o spool.
SPOOL off;
--Permite que o arquivo seja executavel.
!chmod +x &1;
--Finalizar.
exit;

