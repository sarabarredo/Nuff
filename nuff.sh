#!/bin/bash

# Establecer colores principales
sin_color='\033[0m'
rojo='\033[0;31m'
cyan='\033[1;36m'
rosa='\e[95m'
amarillo='\033[0;33m'

# Función para validar dirección IP
validar_ip() {
    local ip=$1
    local stat=1

    # Patrón para validar IPv4
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # Verificar que cada octeto esté entre 0-255
        IFS='.' read -r -a octetos <<< "$ip"
        [[ ${octetos[0]} -le 255 && ${octetos[1]} -le 255 && \
           ${octetos[2]} -le 255 && ${octetos[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Función para verificar si una herramienta está instalada
verificar_herramienta() {
    local herramienta=$1
    if ! command -v $herramienta &> /dev/null; then
        echo -e "${rojo}[!] $herramienta no está instalado.${sin_color}"
        return 1
    fi
    return 0
}

# Función para ejecutar ffuf
ejecutar_ffuf() {
    local ip=$1
    local puerto=$2
    
    echo
    echo -e "${amarillo}[*] Configurando FFUF para fuzzing de directorios${sin_color}"
    
    # Solicitar puerto si no se proporcionó
    if [ -z "$puerto" ]; then
        echo -en "${amarillo}┌─[${rosa}🌐${amarillo}]─[Introduce el puerto (ej: 80)${amarillo}]\n└──╼ ${sin_color}"
        read puerto
    fi
    
    # Solicitar palabra para el fuzzing
    echo -en "${amarillo}┌─[${rosa}📁${amarillo}]─[Introduce la palabra para fuzzing (ej: FUZZ)${amarillo}]\n└──╼ ${sin_color}"
    read palabra_fuzz
    
    # Solicitar diccionario
    echo -en "${amarillo}┌─[${rosa}📚${amarillo}]─[Ruta del diccionario (ej: /usr/share/wordlists/dirb/common.txt)${amarillo}]\n└──╼ ${sin_color}"
    read diccionario
    
    # Verificar si el diccionario existe
    if [ ! -f "$diccionario" ]; then
        echo -e "${rojo}[!] El archivo de diccionario no existe.${sin_color}"
        return 1
    fi
    
    # Ejecutar ffuf
    echo -e "${cyan}[*] Iniciando fuzzing en http://$ip:$puerto/${palabra_fuzz}${sin_color}"
    ffuf -w "$diccionario" -u "http://$ip:$puerto/FUZZ" -fc 404 -mc 200,301,302,307,401,403 -c -v
    
    echo -e "${cyan}[*] Fuzzing completado. Resultados mostrados arriba.${sin_color}"
}

# Evaluar si el usuario es root
if [ $(id -u) -ne 0 ]; then
	echo -e "${rojo}[!] Debes ser usuario root para ejecutar el script.${sin_color}"
	exit
fi

# Verificar dependencias
echo -e "${amarillo}[*] Verificando dependencias...${sin_color}"
verificar_herramienta "nmap" || {
    echo -e "${rojo}[!] Instalando nmap...${sin_color}" 
    apt update >/dev/null && apt install nmap -y >/dev/null && echo -e "Dependencias instaladas"
}

verificar_herramienta "ffuf" || {
    echo -e "${amarillo}[*] FFUF no está instalado. Se omitirá la opción de fuzzing.${sin_color}"
    ffuf_instalado=false
}

clear

# Mostrar banner
echo -e "${cyan}"
echo "  _   _        __  __ "
echo " | \ | |_   _ / _|/ _|"
echo " |  \| | | | | |_| |_ "
echo " | |\  | |_| |  _|  _|"
echo " |_| \_|\__,_|_| |_|  "
echo -e "${sin_color}"
echo
echo -e "${rosa}═╡ Nuff v1.0 by h4shb3e ╞═${sin_color}"
echo

# Solicitar IP con validación
while true; do
    echo -en "${amarillo}┌─[${rosa}📍${amarillo}]─[Introduce la IP objetivo${amarillo}]\n└──╼ ${sin_color}"
    read ip
    echo -en "${sin_color}"
    
    if validar_ip "$ip"; then
        break
    else
        echo
        echo -e "${rojo}[!] IP no válida. Formato correcto: XXX.XXX.XXX.XXX (0-255)${sin_color}"
        echo
    fi
done

while true; do
    echo
    echo -e "${rosa}╔══════════════════════════════════════╗${sin_color}"
    echo -e "${rosa}║               OPCIONES               ║${sin_color}"
    echo -e "${rosa}╠══════════════════════════════════════╣${sin_color}"
    echo -e "${rosa}║${sin_color} \e[1m${rosa}1${sin_color}  Escaneo rápido (ruidoso)          ${rosa}║${sin_color}"
    echo -e "${rosa}║${sin_color} \e[1m${rosa}2${sin_color}  Escaneo normal                    ${rosa}║${sin_color}"
    echo -e "${rosa}║${sin_color} \e[1m${rosa}3${sin_color}  Escaneo silencioso (más lento)    ${rosa}║${sin_color}"
    echo -e "${rosa}║${sin_color} \e[1m${rosa}4${sin_color}  Escaneo de servicios y versiones  ${rosa}║${sin_color}"
    
    # Solo mostrar opción de FFUF si está instalado
    if [ "$ffuf_instalado" != "false" ]; then
        echo -e "${rosa}║${sin_color} \e[1m${rosa}5${sin_color}  Fuzzing de directorios (FFUF)     ${rosa}║${sin_color}"
        echo -e "${rosa}║${sin_color} \e[1m${rosa}6${sin_color}  Salir                             ${rosa}║${sin_color}"
    else
        echo -e "${rosa}║${sin_color} \e[1m${rosa}5${sin_color}  Salir                             ${rosa}║${sin_color}"
    fi
    
    echo -e "${rosa}╚══════════════════════════════════════╝${sin_color}"
    echo
    read -p "Selecciona una opción: " opcion

    case $opcion in
    1)
        clear && echo "Escaneando..." && nmap -p- --open --min-rate 5000 -T5 -sS -Pn -n -v $ip > escaneo_rapido.txt && echo -e "${cyan}Reporte generado en el fichero escaneo_rapido.txt${sin_color}"
        exit
        ;;
    2)
        clear && echo "Escaneando..." && nmap -p- --open $ip > escaneo_normal.txt && echo -e "${cyan}Reporte generado en el fichero escaneo_normal.txt${sin_color}"
        exit
        ;;
    3)
        clear && echo "Escaneando..." && nmap -p- -T2 -sS -Pn -f $ip > escaneo_silencioso.txt && echo -e "${cyan}Reporte generado en el fichero escaneo_silencioso.txt${sin_color}"
        exit
        ;;
    4)
        clear && echo "Escaneando..." && nmap -sV -sC $ip > escaneo_servicios.txt && echo -e "${cyan}Reporte generado en el fichero escaneo_servicios.txt${sin_color}"
        exit
        ;;
    5)
        if [ "$ffuf_instalado" != "false" ]; then
            ejecutar_ffuf "$ip"
        else
            break
        fi
        ;;
    6)
        if [ "$ffuf_instalado" != "false" ]; then
            break
        else
            echo -e "Por favor, introduce una opción válida"
        fi
        ;;
    *)
        echo -e "Por favor, introduce una opción válida"
        ;;
    esac
done