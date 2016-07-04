#!/bin/bash
#===================================================================================================#
# PROYECTO            : [6172] AUTOMATIZACIÓN DE MEDIOS MAGNÉTICOS
# DESARROLLADOR	      : SUD Ericka FLores
# LIDER CONECEL       : SIS Alan Pabo
# LIDER PDS           : SUD José Sotomayor
# FECHA               : 19/01/2012
# MODIFICADO	      : 28/06/2012
# COMENTARIO          : Despachador de Notificacon de Envio de Entidades Financieras 
#===================================================================================================#

#Limpiar Pantalla
clear

#------------------------------------------------#
# Ruta para el .config:
#------------------------------------------------#
#ruta_config=/procesos/home/sisapa/6172
ruta_config=/home/gsioper/procesos/mmag_ope


#------------------------------------------------#
# Datos de Conexion con Expect:
#------------------------------------------------#

#IP REMOTO EXPECT
ipremoto=192.168.10.5
#ipremoto=192.168.37.196

#RUTA REMOTO EXPECT
ruta_expect=/procesos/home/gsioper/ftp/mmagne/
#ruta_expect=/home/sisapa/6172/

#USER
userremoto=gsioper
#userremoto=sisapa

#PASSWORD
passExpect=192.168.10.5
passremoto=`/home/gsioper/key/pass $passExpect`
#passremoto=sisapa

#--------------------------------------------------------#
# Repositorio en donden se guarda el archivo
#--------------------------------------------------------#

#RUTA ORIGEN OPERACIONES
ruta_oper=/home/gsioper/procesos/mmag_ope/notificaciones/
#ruta_oper=/procesos/home/sisapa/6172/notificaciones/


#ARCHIVO DE CONFIGURACION
archivo_config="entidades.config"

#DIRECTORIO FINAL DONDE SE GENERA EL ARCHIVO EN EXPECT
ruta_final=envio

#RUTA DONDE ESTA UBICADO EL SHELL
ruta_shell=/home/gsioper/procesos/mmag_ope
#ruta_shell=/procesos/home/sisapa/6172

#NOMBRES DE LOG
log_ftp=trans_ftp.log
nombre_log=result_ftp.log

#NOMBRE DE ARCHIVO BANDERA
arch_band=bandera.txt


#---------------------------------------------------#
#Validación si existe el Archivo de Configuración
#---------------------------------------------------#
if ! [ -s "$ruta_config/$archivo_config" ]; then
     echo "El archivo de configuracion no existe..."
     exit 1 #Termina con error
fi


#=======================================================================================#
fecha=`date +%Y%m%d`
#=======================================================================================#

cd $ruta_shell/


#---------------------------------------------------------------------------------------#
# Obtener los nombres de la Entidades Financieras del archivo de configuración
#---------------------------------------------------------------------------------------#
NumLine_ini=`cat $archivo_config | grep -n "INI_CAMPOS_BC" | cut -d: -f1`
NumLine_ini=`expr $NumLine_ini + 1`
NumLine_fin=`cat $archivo_config | grep -n "FIN_CAMPOS_BC" | cut -d: -f1`
NumLine_fin=`expr $NumLine_fin - 1`
cat $archivo_config | head -n $NumLine_fin | tail -n +$NumLine_ini > entidades.txt


# Ciclo de lanzamiento de los shell de envio
while read line
do
if ! [ -z $line ]; then
ruta_nodo="$ruta_expect$line/$ruta_final"
archivo="institucion_$line"".txt"

#-----------------------------------#
#Conexion a Expect desde Operaciones
#-----------------------------------#
echo "inicio ftp"
ftp -in -v > $log_ftp <<END
open $ipremoto
user $userremoto $passremoto
ascii mode
cd $ruta_nodo
lcd $ruta_oper$line
mget $archivo
mdelete $archivo
bye
END
echo "fin ftp"	


#------------------------------------------#
#Validacion de la transferencia
#------------------------------------------#
sucess=`cat $log_ftp | grep "226" | wc -l`
if [ $sucess -ne 0 ]; then
echo "Transferencia realizada con éxito."
rm -f $log_ftp

#---------------------------------------------------#
#Validación si existe el Archivo de Bandera
#---------------------------------------------------#
if ! [ -s "$ruta_oper$line/$arch_band" ]; then
     echo "El archivo de confirmacion no existe..."   

else

#var=`cat $ruta_oper$line/$arch_band` --> SUD EF 28/06/2012
var=`cat $ruta_oper$line/$arch_band | grep -w "bandera" | cut -d'=' -f2`
usuario=`cat $ruta_oper$line/$arch_band | grep -w "usuario" | cut -d'=' -f2`
correo=`cat $ruta_oper$line/$arch_band | grep -w "mail" | cut -d'=' -f2`


#------------------------------------------------------------------#
#Lectura del Archivo de Bandera 
# 0: Llama al Shell de transferencia
# 1: No lo va a ejecutar
#------------------------------------------------------------------#

if [ $var -eq 0 ]; then
echo "LLamando al shell que envia mail de notificacion"
sh shell_mail_notif_envio.sh  "$ruta_oper$line" "$line"  "$archivo" "$usuario" "$correo"

#------------------------------------------------------------------#
#Actualiza bandera a 1 y los demas parametros usuario y mail
#------------------------------------------------------------------#
#echo "1">"$ruta_oper$line/$arch_band" --> SUD EF 28/06/2012
echo "bandera=1">"$ruta_oper$line/$arch_band"
echo "usuario=$usuario">>"$ruta_oper$line/$arch_band"
echo "mail=$correo">>"$ruta_oper$line/$arch_band"
#------------------------------------------------------------------#
fi

fi

else
echo "Error al mometo de transferir el acrhivo."
cat $log_ftp | tr -d '\r' >> $nombre_log
fi

#===========================================================
echo "fin del shell de notificacion de envio"
borrar="$ruta_oper$line/$archivo"
rm -f $borrar

fi
done < entidades.txt
#===========================================================

#Eliminar archivo txt
rm -f entidades.txt
exit 0 #Termina con éxito