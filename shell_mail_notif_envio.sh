#===================================================================================================#
# PROYECTO            : [6172] AUTOMATIZACIÓN DE MEDIOS MAGNÉTICOS
# DESARROLLADOR	      : SUD Ericka FLores
# LIDER CONECEL       : SIS Alan Pabo
# LIDER PDS           : SUD José Sotomayor
# FECHA               : 23/01/2012
# Modificado	      : 28/06/2012
# COMENTARIO          : Notifica Envio de Archivo a los bancos 
#===================================================================================================#
#----------------------------------#
# Recibiendo Parámetros:
#----------------------------------#
LocalFile="$1"
RutaLog=$LocalFile/log
Banco="$2"
File="$3"
usuario="$4"
Correo="$5"

Host=130.2.18.61
From=OPERACIONES@claro.com.ec
To="$correo;ericka.flores@sasf.net;apabo@claro.com.ec;jose.sotomayor@sasf.net"
Subject="mmag_envio :: CONFIRMACION DE ENVIO -  $Banco "`date +'%d/%m/%Y'`" ::"

#texto=`cat $LocalFile/$File | tr '\n' ' '` --> SUD EF 28/06/2012

#Otiene solo el contenido del Mensaje del archivo
texto=`cat $LocalFile/$File | grep -w "Mensaje " | cut -d':' -f2` 

#------------------------------------------------#
# Ejecuta el proceso de Envío de Mails
#------------------------------------------------#
cat > rpt_bcos.txt <<eof
sendMail.host = $Host
sendMail.from = $From
sendMail.to   = $To
sendMail.subject = $Subject
sendMail.message ="$texto Enviado por el usuario $usuario "
eof
/opt/java1.4/bin/java -jar sendMail.jar rpt_bcos.txt 2>"$RutaLog/error_mail.log"
if [ -s error_mail.log ];then
echo `date +'%d/%m/%Y %H:%M:%S'` "   Se produjo un error al enviar el mail. Revise $RutaLog/error_mail.log"
exit 1
else
rm -f error_mail.log
echo `date +'%d/%m/%Y %H:%M:%S'` "   Mail Enviado a $To"
fi
rm -f rpt_bcos.txt
exit 0